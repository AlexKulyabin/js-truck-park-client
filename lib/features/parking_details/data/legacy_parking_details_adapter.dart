import '../../../backend/supabase/supabase.dart';
import '../domain/parking_details.dart';

ViewFullParkingDetailsRow parkingDetailsToLegacyRow(ParkingDetails details) =>
    ViewFullParkingDetailsRow({
      'id': details.id,
      'address': details.address,
      'latitude': details.latitude,
      'longitude': details.longitude,
      'total_spaces': details.totalSpaces,
      'rating': details.rating,
      'stars_1': details.stars1,
      'stars_2': details.stars2,
      'stars_3': details.stars3,
      'stars_4': details.stars4,
      'stars_5': details.stars5,
      'reviews_count': details.reviewsCount,
      'photos_count': details.photosCount,
      'all_photos': details.photos
          ?.map(
            (photo) => {
              'url': photo.url,
              'photo_date': photo.photoDate,
            },
          )
          .toList(growable: false),
      'is_favorited': details.isFavorited,
      'has_gas_station': details.hasGasStation,
      'has_shower': details.hasShower,
      'has_laundry': details.hasLaundry,
      'has_hotel': details.hasHotel,
      'has_shop': details.hasShop,
      'has_recreation_area': details.hasRecreationArea,
    });

ViewReviewsWithUsersRow parkingReviewToLegacyRow(ParkingReview review) =>
    ViewReviewsWithUsersRow({
      'id': review.id,
      'parking_id': review.parkingId,
      'created_at': review.createdAt?.toIso8601String(),
      'user_id': review.userId,
      'comment': review.comment,
      'average_score': review.averageScore,
      'author_name': review.authorName,
      'author_avatar': review.authorAvatar,
      'review_photos': review.reviewPhotos,
    });
