import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:j_s_truck_park/features/reviews/application/user_reviews_controller.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_complaint_summary.dart';
import 'package:j_s_truck_park/features/reviews/domain/user_review_summary.dart';
import 'package:j_s_truck_park/features/reviews/presentation/reviews_and_complaints_view.dart';
import 'package:j_s_truck_park/flutter_flow/internationalization.dart';

const _review = UserReviewSummary(
  id: 1,
  parkingAddress: 'Review parking',
  createdAt: null,
  averageScore: 4,
  comment: 'Short review',
  authorAvatarUrl: null,
  photoUrls: [],
);

const _complaint = UserComplaintSummary(
  id: 2,
  parkingAddress: 'Complaint parking',
  reportDate: null,
  reportType: 'Report1',
  comment: 'Short complaint',
  parkingPhotoUrls: [],
  photosCount: null,
);

Widget _buildSubject({
  required UserReviewsState state,
  VoidCallback? onBack,
  ValueChanged<UserReviewsTab>? onTabSelected,
  VoidCallback? onRetry,
  ValueChanged<UserComplaintSummary>? onComplaintPhotoSelected,
  Brightness brightness = Brightness.light,
}) =>
    MaterialApp(
      localizationsDelegates: const [
        FFLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ru')],
      locale: const Locale('en'),
      theme: ThemeData(brightness: brightness, useMaterial3: false),
      home: Scaffold(
        body: ReviewsAndComplaintsView(
          state: state,
          onBack: onBack ?? () {},
          onTabSelected: onTabSelected ?? (_) {},
          onRetry: onRetry ?? () {},
          onComplaintPhotoSelected: onComplaintPhotoSelected ?? (_) {},
        ),
      ),
    );

void main() {
  testWidgets('renders reviews loading state', (tester) async {
    await tester.pumpWidget(
      _buildSubject(state: const UserReviewsState.initial()),
    );

    expect(
        find.byKey(ReviewsAndComplaintsView.reviewsLoadingKey), findsOneWidget);
    expect(find.text('Reviews'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders existing reviews empty message', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        state: const UserReviewsState(
          selectedTab: UserReviewsTab.reviews,
          reviews: UserReviewsListState<UserReviewSummary>(
            phase: UserReviewsLoadPhase.loaded,
            items: [],
          ),
          complaints: UserReviewsListState<UserComplaintSummary>.initial(),
        ),
      ),
    );

    expect(
        find.byKey(ReviewsAndComplaintsView.reviewsEmptyKey), findsOneWidget);
    expect(
      find.text('List of your reviews will be displayed here'),
      findsOneWidget,
    );
  });

  testWidgets('renders typed review cards in dark mode', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        brightness: Brightness.dark,
        state: const UserReviewsState(
          selectedTab: UserReviewsTab.reviews,
          reviews: UserReviewsListState<UserReviewSummary>(
            phase: UserReviewsLoadPhase.loaded,
            items: [_review],
          ),
          complaints: UserReviewsListState<UserComplaintSummary>.initial(),
        ),
      ),
    );

    expect(find.byKey(ReviewsAndComplaintsView.reviewsListKey), findsOneWidget);
    expect(find.text('Review parking'), findsOneWidget);
    expect(find.text('Short review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects complaints tab and renders complaint cards',
      (tester) async {
    UserReviewsTab? selected;
    await tester.pumpWidget(
      _buildSubject(
        state: const UserReviewsState(
          selectedTab: UserReviewsTab.complaints,
          reviews: UserReviewsListState<UserReviewSummary>.initial(),
          complaints: UserReviewsListState<UserComplaintSummary>(
            phase: UserReviewsLoadPhase.loaded,
            items: [_complaint],
          ),
        ),
        onTabSelected: (tab) => selected = tab,
      ),
    );

    expect(
      find.byKey(ReviewsAndComplaintsView.complaintsListKey),
      findsOneWidget,
    );
    expect(find.text('Complaint parking'), findsOneWidget);
    expect(find.text('Parking does not exist'), findsOneWidget);

    await tester.tap(find.byKey(ReviewsAndComplaintsView.reviewsTabKey));
    expect(selected, UserReviewsTab.reviews);
  });

  testWidgets('retries failures without rendering raw details', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _buildSubject(
        state: const UserReviewsState(
          selectedTab: UserReviewsTab.reviews,
          reviews: UserReviewsListState<UserReviewSummary>(
            phase: UserReviewsLoadPhase.failure,
            items: [],
          ),
          complaints: UserReviewsListState<UserComplaintSummary>.initial(),
        ),
        onRetry: () => retries++,
      ),
    );

    await tester.tap(find.byKey(ReviewsAndComplaintsView.reviewsFailureKey));

    expect(retries, 1);
    expect(find.textContaining('database'), findsNothing);
  });
}
