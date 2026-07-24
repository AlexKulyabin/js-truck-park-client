import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_complaint_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_review_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_reviews_repository.dart';
import 'package:j_s_truck_park/features/reviews/presentation/reviews_and_complaints_view.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';
import 'package:j_s_truck_park/reviews/reviews_and_complaints/reviews_and_complaints_widget.dart';

class _FakeRepository implements UserReviewsRepository {
  final reviewUserIds = <String>[];

  @override
  Future<List<UserReviewSummary>> fetchOwnedReviews(String userId) async {
    reviewUserIds.add(userId);
    return const [];
  }

  @override
  Future<List<UserComplaintSummary>> fetchOwnedComplaints(String userId) async {
    return const [];
  }
}

Widget _buildSubject(_FakeRepository repository) => MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      home: ReviewsAndComplaintsWidget(
        repository: repository,
        userId: 'user-1',
      ),
    );

void main() {
  test('keeps the public route contract', () {
    expect(ReviewsAndComplaintsWidget.routeName, 'ReviewsAndComplaints');
    expect(ReviewsAndComplaintsWidget.routePath, '/reviewsAndComplaints');
  });

  testWidgets('loads the screen through the injected owner boundary',
      (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(_buildSubject(repository));
    await tester.pumpAndSettle();

    expect(repository.reviewUserIds, ['user-1']);
    expect(
      find.byKey(ReviewsAndComplaintsView.reviewsEmptyKey),
      findsOneWidget,
    );
    expect(find.text('Reviews'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
