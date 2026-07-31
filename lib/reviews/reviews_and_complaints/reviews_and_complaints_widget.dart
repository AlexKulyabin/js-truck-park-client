import 'dart:async';

import '/auth/supabase_auth/auth_util.dart';
import '/features/reviews/application/user_reviews_controller.dart';
import '/features/reviews/data/supabase_user_reviews_repository.dart';
import '/features/reviews/domain/user_complaint_summary.dart';
import '/features/reviews/domain/user_reviews_repository.dart';
import '/features/reviews/presentation/reviews_and_complaints_view.dart';
import '/features/reviews/presentation/user_complaint_photo_navigation.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'reviews_and_complaints_model.dart';
export 'reviews_and_complaints_model.dart';

class ReviewsAndComplaintsWidget extends StatefulWidget {
  const ReviewsAndComplaintsWidget({
    super.key,
    this.repository,
    this.userId,
  });

  final UserReviewsRepository? repository;
  final String? userId;

  static String routeName = 'ReviewsAndComplaints';
  static String routePath = '/reviewsAndComplaints';

  @override
  State<ReviewsAndComplaintsWidget> createState() =>
      _ReviewsAndComplaintsWidgetState();
}

class _ReviewsAndComplaintsWidgetState
    extends State<ReviewsAndComplaintsWidget> {
  late ReviewsAndComplaintsModel _model;
  late final UserReviewsController _controller;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewsAndComplaintsModel());
    _controller = UserReviewsController(
      repository: widget.repository ?? SupabaseUserReviewsRepository(),
      userId: widget.userId ?? currentUserUid,
    )..addListener(_onStateChanged);
    unawaited(_controller.loadReviews());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChanged)
      ..dispose();
    _model.dispose();

    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openComplaintPhoto(UserComplaintSummary complaint) {
    final queryParameters = buildComplaintPhotoQueryParameters(complaint);
    if (queryParameters.isEmpty) {
      return;
    }

    context.pushNamed(
      PhotoDetailedWidget.routeName,
      queryParameters: queryParameters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: ReviewsAndComplaintsView(
          state: _controller.state,
          onBack: () => Navigator.pop(context),
          onTabSelected: (tab) => unawaited(_controller.selectTab(tab)),
          onRetry: () => unawaited(_controller.retrySelected()),
          onComplaintPhotoSelected: _openComplaintPhoto,
        ),
      ),
    );
  }
}
