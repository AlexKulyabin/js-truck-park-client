import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../application/user_reviews_controller.dart';
import '../domain/user_complaint_summary.dart';
import 'user_complaint_card.dart';
import 'user_review_card.dart';

class ReviewsAndComplaintsView extends StatelessWidget {
  const ReviewsAndComplaintsView({
    super.key,
    required this.state,
    required this.onBack,
    required this.onTabSelected,
    required this.onRetry,
    required this.onComplaintPhotoSelected,
  });

  static const reviewsTabKey = Key('user-reviews-tab');
  static const complaintsTabKey = Key('user-complaints-tab');
  static const reviewsLoadingKey = Key('user-reviews-loading');
  static const complaintsLoadingKey = Key('user-complaints-loading');
  static const reviewsFailureKey = Key('user-reviews-failure');
  static const complaintsFailureKey = Key('user-complaints-failure');
  static const reviewsEmptyKey = Key('user-reviews-empty');
  static const complaintsEmptyKey = Key('user-complaints-empty');
  static const reviewsListKey = Key('user-reviews-loaded');
  static const complaintsListKey = Key('user-complaints-loaded');

  final UserReviewsState state;
  final VoidCallback onBack;
  final ValueChanged<UserReviewsTab> onTabSelected;
  final VoidCallback onRetry;
  final ValueChanged<UserComplaintSummary> onComplaintPhotoSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _header(context),
          _tabs(context),
          Expanded(child: _selectedBody(context)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
      child: Stack(
        alignment: const AlignmentDirectional(-1.0, 0.0),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0,
                      11.0,
                      0.0,
                      11.0,
                    ),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        '6evvc10q' /* Reviews */,
                      ),
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .fontStyle,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
            child: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  4.0,
                  4.0,
                  4.0,
                  4.0,
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 24.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
      child: Container(
        width: double.infinity,
        height: 32.0,
        decoration: BoxDecoration(
          color: const Color(0x1E767680),
          borderRadius: BorderRadius.circular(9.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(2.0, 2.0, 2.0, 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _tab(
                  context,
                  tab: UserReviewsTab.reviews,
                  selectedKey: '7qsaka2q' /* Reviews  */,
                  unselectedKey: '4tqqsecp' /* Reviews  */,
                ),
              ),
              Expanded(
                child: _tab(
                  context,
                  tab: UserReviewsTab.complaints,
                  selectedKey: '9kj8miy2' /* Complaints */,
                  unselectedKey: 'mjvppaw8' /* Complaints */,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required UserReviewsTab tab,
    required String selectedKey,
    required String unselectedKey,
  }) {
    final isSelected = state.selectedTab == tab;
    final textKey = isSelected ? selectedKey : unselectedKey;
    final weight = isSelected ? FontWeight.w600 : FontWeight.normal;

    final content = Container(
      key: tab == UserReviewsTab.reviews ? reviewsTabKey : complaintsTabKey,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? FlutterFlowTheme.of(context).secondaryBackground
            : null,
        boxShadow: isSelected
            ? const [
                BoxShadow(
                  blurRadius: 8.0,
                  color: Color(0x1F000000),
                  offset: Offset(0.0, 3.0),
                ),
              ]
            : null,
        borderRadius: BorderRadius.circular(7.0),
      ),
      child: Align(
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Text(
          FFLocalizations.of(context).getText(textKey),
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.roboto(
                  fontWeight: weight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                fontSize: 13.0,
                letterSpacing: 0.0,
                fontWeight: weight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
        ),
      ),
    );

    if (isSelected) {
      return content;
    }

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => onTabSelected(tab),
      child: content,
    );
  }

  Widget _selectedBody(BuildContext context) {
    return switch (state.selectedTab) {
      UserReviewsTab.reviews => _reviewsBody(context),
      UserReviewsTab.complaints => _complaintsBody(context),
    };
  }

  Widget _reviewsBody(BuildContext context) {
    final reviews = state.reviews;
    if (reviews.phase == UserReviewsLoadPhase.idle ||
        reviews.phase == UserReviewsLoadPhase.loading) {
      return _loading(context, key: reviewsLoadingKey);
    }
    if (reviews.phase == UserReviewsLoadPhase.failure) {
      return _failure(
        context,
        key: reviewsFailureKey,
        assetPath: 'assets/images/star.fill.svg',
      );
    }
    if (reviews.items.isEmpty) {
      return _empty(
        context,
        key: reviewsEmptyKey,
        assetPath: 'assets/images/star.fill.svg',
        textKey: 'chbtvtci' /* List of your reviews will be displayed here */,
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: ListView.separated(
        key: reviewsListKey,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: reviews.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16.0),
        itemBuilder: (context, index) {
          final review = reviews.items[index];
          return UserReviewCard(
            key: ValueKey(review.id),
            review: review,
          );
        },
      ),
    );
  }

  Widget _complaintsBody(BuildContext context) {
    final complaints = state.complaints;
    if (complaints.phase == UserReviewsLoadPhase.idle ||
        complaints.phase == UserReviewsLoadPhase.loading) {
      return _loading(context, key: complaintsLoadingKey);
    }
    if (complaints.phase == UserReviewsLoadPhase.failure) {
      return _failure(
        context,
        key: complaintsFailureKey,
        assetPath: 'assets/images/danger.svg',
      );
    }
    if (complaints.items.isEmpty) {
      return _empty(
        context,
        key: complaintsEmptyKey,
        assetPath: 'assets/images/danger.svg',
        textKey:
            'pdmi0b47' /* A list of your complaints will be displayed here */,
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: ListView.separated(
        key: complaintsListKey,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: complaints.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16.0),
        itemBuilder: (context, index) {
          final complaint = complaints.items[index];
          return UserComplaintCard(
            key: ValueKey(complaint.id),
            complaint: complaint,
            onPhotoSelected: onComplaintPhotoSelected,
          );
        },
      ),
    );
  }

  Widget _failure(
    BuildContext context, {
    required Key key,
    required String assetPath,
  }) {
    return InkWell(
      key: key,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onRetry,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: SvgPicture.asset(
                assetPath,
                width: 96.0,
                height: 96.0,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              FFLocalizations.of(context).getVariableText(
                enText: 'Could not load the list. Tap to try again',
                ruText: 'Не удалось загрузить список. Нажмите, чтобы повторить',
              ),
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.roboto(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
            ),
          ].divide(const SizedBox(height: 16.0)),
        ),
      ),
    );
  }

  Widget _loading(BuildContext context, {Key? key}) {
    return Center(
      child: SizedBox(
        key: key,
        width: 50.0,
        height: 50.0,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            FlutterFlowTheme.of(context).primary,
          ),
        ),
      ),
    );
  }

  Widget _empty(
    BuildContext context, {
    required Key key,
    required String assetPath,
    required String textKey,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(0.0),
          child: SvgPicture.asset(
            assetPath,
            width: 96.0,
            height: 96.0,
            fit: BoxFit.cover,
          ),
        ),
        Text(
          FFLocalizations.of(context).getText(textKey),
          style: FlutterFlowTheme.of(context).labelLarge.override(
                font: GoogleFonts.roboto(
                  fontWeight:
                      FlutterFlowTheme.of(context).labelLarge.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
              ),
        ),
      ].divide(const SizedBox(height: 16.0)),
    );
  }
}
