import '../../../auth/supabase_auth/auth_util.dart';
import '../../../backend/supabase/supabase.dart';
import '../../../flutter_flow/upload_data.dart';
import '../domain/parking_submission_draft.dart';
import '../domain/parking_submission_repository.dart';

typedef ParkingSubmissionUserIdProvider = String Function();
typedef ParkingSubmissionClock = DateTime Function();

abstract interface class ParkingSubmissionDataSource {
  Future<String> insertParking(Map<String, dynamic> values);

  Future<String> uploadPhoto({
    required String bucketName,
    required ParkingSubmissionPhoto photo,
    required String storagePath,
  });

  Future<void> insertParkingPhoto(Map<String, dynamic> values);
}

class GeneratedParkingSubmissionDataSource
    implements ParkingSubmissionDataSource {
  @override
  Future<String> insertParking(Map<String, dynamic> values) async {
    final row = await ParkingsTable().insert(values);
    final id = row.id;
    if (id == null || id.isEmpty) {
      throw const ParkingSubmissionException(
        ParkingSubmissionFailureKind.invalidData,
      );
    }
    return id;
  }

  @override
  Future<String> uploadPhoto({
    required String bucketName,
    required ParkingSubmissionPhoto photo,
    required String storagePath,
  }) async {
    final urls = await uploadSupabaseStorageFiles(
      bucketName: bucketName,
      selectedFiles: [
        SelectedFile(
          storagePath: storagePath,
          bytes: photo.bytes,
          originalFilename: photo.originalFilename ?? photo.name,
        ),
      ],
    );
    if (urls.length != 1 || urls.first.isEmpty) {
      throw const ParkingSubmissionException(
        ParkingSubmissionFailureKind.invalidData,
      );
    }
    return urls.first;
  }

  @override
  Future<void> insertParkingPhoto(Map<String, dynamic> values) async {
    await ParkingPhotosTable().insert(values);
  }
}

class SupabaseParkingSubmissionRepository
    implements ParkingSubmissionRepository {
  SupabaseParkingSubmissionRepository({
    ParkingSubmissionDataSource? dataSource,
    ParkingSubmissionUserIdProvider? userIdProvider,
    ParkingSubmissionClock? clock,
  })  : _dataSource = dataSource ?? GeneratedParkingSubmissionDataSource(),
        _userIdProvider = userIdProvider ?? _currentUserId,
        _clock = clock ?? DateTime.now;

  static const parkingPhotoBucket = 'parking_content';

  final ParkingSubmissionDataSource _dataSource;
  final ParkingSubmissionUserIdProvider _userIdProvider;
  final ParkingSubmissionClock _clock;

  @override
  Future<ParkingSubmissionResult> submit(
    ParkingSubmissionDraft draft,
  ) async {
    if (!draft.isValid || draft.photos.any((photo) => !photo.hasBytes)) {
      throw const ParkingSubmissionException(
        ParkingSubmissionFailureKind.invalidInput,
      );
    }

    final userId = _userIdProvider();
    if (userId.isEmpty) {
      throw const ParkingSubmissionException(
        ParkingSubmissionFailureKind.unauthenticated,
      );
    }

    var parkingCreated = false;
    try {
      final parkingId = await _dataSource.insertParking(
        _parkingPayload(
          draft: draft,
          userId: userId,
          createdAt: _clock(),
        ),
      );
      parkingCreated = true;

      final photoUrls = <String>[];
      for (var index = 0; index < draft.photos.length; index++) {
        final photo = draft.photos[index];
        final url = await _dataSource.uploadPhoto(
          bucketName: parkingPhotoBucket,
          photo: photo,
          storagePath: photo.storagePath(
            parkingId: parkingId,
            index: index,
          ),
        );
        photoUrls.add(url);
        await _dataSource.insertParkingPhoto({
          'url': url,
          'parking_id': parkingId,
          'user_id': userId,
        });
      }

      return ParkingSubmissionResult(
        parkingId: parkingId,
        photoUrls: List.unmodifiable(photoUrls),
      );
    } on ParkingSubmissionException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ParkingSubmissionException(
        parkingCreated
            ? ParkingSubmissionFailureKind.partialFailure
            : _mapPostgrestFailure(error),
      );
    } catch (_) {
      throw ParkingSubmissionException(
        parkingCreated
            ? ParkingSubmissionFailureKind.partialFailure
            : ParkingSubmissionFailureKind.unavailable,
      );
    }
  }

  Map<String, dynamic> _parkingPayload({
    required ParkingSubmissionDraft draft,
    required String userId,
    required DateTime createdAt,
  }) =>
      {
        'total_spaces': draft.totalSpaces,
        'has_gas_station': draft.services.hasGasStation,
        'has_shower': draft.services.hasShower,
        'has_laundry': draft.services.hasLaundry,
        'has_hotel': draft.services.hasHotel,
        'has_shop': draft.services.hasShop,
        'has_recreation_area': draft.services.hasRecreationArea,
        'address': draft.address,
        'latitude': draft.latitude,
        'longitude': draft.longitude,
        'address_lower': draft.addressLower,
        'created_by': userId,
        'created_at': supaSerialize<DateTime>(createdAt),
        'status': 'pending',
      };

  ParkingSubmissionFailureKind _mapPostgrestFailure(PostgrestException error) {
    if (error.code == '42501') {
      return ParkingSubmissionFailureKind.forbidden;
    }
    return ParkingSubmissionFailureKind.unavailable;
  }
}

String _currentUserId() => currentUserUid;
