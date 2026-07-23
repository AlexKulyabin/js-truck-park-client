import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core/config/app_config.dart';
import '/features/parking_details/application/parking_details_controller.dart';
import '/features/parking_details/data/legacy_parking_details_adapter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/reviews/report_create/report_create_widget.dart';
import '/reviews/review_card_parking_details/review_card_parking_details_widget.dart';
import '/reviews/review_create/review_create_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import 'dart:async';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'reviews_tab_model.dart';
export 'reviews_tab_model.dart';

class ReviewsTabWidget extends StatefulWidget {
  const ReviewsTabWidget({
    super.key,
    required this.parkingRow,
    required this.detailsController,
  });

  final ViewFullParkingDetailsRow? parkingRow;
  final ParkingDetailsController detailsController;

  static const loadingKey = Key('public-parking-reviews-loading');
  static const failureKey = Key('public-parking-reviews-failure');

  @override
  State<ReviewsTabWidget> createState() => _ReviewsTabWidgetState();
}

class _ReviewsTabWidgetState extends State<ReviewsTabWidget> {
  late ReviewsTabModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewsTabModel());
    widget.detailsController.addListener(_onReviewsStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.detailsController.loadReviews());
        safeSetState(() {});
      }
    });
  }

  void _onReviewsStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.detailsController.removeListener(_onReviewsStateChanged);
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Builder(
      builder: (context) {
        final state = widget.detailsController.state;
        if (state.reviewsPhase == ParkingDetailsLoadPhase.idle ||
            state.reviewsPhase == ParkingDetailsLoadPhase.loading) {
          return Center(
            child: SizedBox(
              key: ReviewsTabWidget.loadingKey,
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
        if (state.reviewsPhase == ParkingDetailsLoadPhase.failure) {
          return InkWell(
            key: ReviewsTabWidget.failureKey,
            onTap: () => unawaited(widget.detailsController.loadReviews()),
            child: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        final containerViewReviewsWithUsersRowList =
            state.reviews.map(parkingReviewToLegacyRow).toList(growable: false);

        return Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 46.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            valueOrDefault<String>(
                              widget!.parkingRow?.rating?.toString(),
                              '4.0',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .displayMedium
                                .override(
                                  font: GoogleFonts.roboto(
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .displayMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 40.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .displayMedium
                                      .fontStyle,
                                ),
                          ),
                          Text(
                            valueOrDefault<String>(
                              '${containerViewReviewsWithUsersRowList.length.toString()} ${FFLocalizations.of(context).getVariableText(
                                enText: ' reviews ',
                                ruText: 'отзывов',
                              )}',
                              'reviews ',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .labelMedium
                                .override(
                                  font: GoogleFonts.roboto(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          RatingBar.builder(
                            onRatingUpdate: (newValue) => safeSetState(
                                () => _model.ratingBarValue1 = newValue),
                            itemBuilder: (context, index) => Icon(
                              Icons.star_rounded,
                              color: FlutterFlowTheme.of(context).tertiary,
                            ),
                            direction: Axis.horizontal,
                            initialRating: _model.ratingBarValue1 ??= 5.0,
                            unratedColor: Colors.transparent,
                            itemCount: 5,
                            itemPadding:
                                EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                            itemSize: 10.0,
                            glowColor: FlutterFlowTheme.of(context).tertiary,
                          ),
                          RatingBar.builder(
                            onRatingUpdate: (newValue) => safeSetState(
                                () => _model.ratingBarValue2 = newValue),
                            itemBuilder: (context, index) => Icon(
                              Icons.star_rounded,
                              color: FlutterFlowTheme.of(context).tertiary,
                            ),
                            direction: Axis.horizontal,
                            initialRating: _model.ratingBarValue2 ??= 4.0,
                            unratedColor: Colors.transparent,
                            itemCount: 5,
                            itemPadding:
                                EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                            itemSize: 10.0,
                            glowColor: FlutterFlowTheme.of(context).tertiary,
                          ),
                          RatingBar.builder(
                            onRatingUpdate: (newValue) => safeSetState(
                                () => _model.ratingBarValue3 = newValue),
                            itemBuilder: (context, index) => Icon(
                              Icons.star_rounded,
                              color: FlutterFlowTheme.of(context).tertiary,
                            ),
                            direction: Axis.horizontal,
                            initialRating: _model.ratingBarValue3 ??= 3.0,
                            unratedColor: Colors.transparent,
                            itemCount: 5,
                            itemPadding:
                                EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                            itemSize: 10.0,
                            glowColor: FlutterFlowTheme.of(context).tertiary,
                          ),
                          RatingBar.builder(
                            onRatingUpdate: (newValue) => safeSetState(
                                () => _model.ratingBarValue4 = newValue),
                            itemBuilder: (context, index) => Icon(
                              Icons.star_rounded,
                              color: FlutterFlowTheme.of(context).tertiary,
                            ),
                            direction: Axis.horizontal,
                            initialRating: _model.ratingBarValue4 ??= 2.0,
                            unratedColor: Colors.transparent,
                            itemCount: 5,
                            itemPadding:
                                EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                            itemSize: 10.0,
                            glowColor: FlutterFlowTheme.of(context).tertiary,
                          ),
                          RatingBar.builder(
                            onRatingUpdate: (newValue) => safeSetState(
                                () => _model.ratingBarValue5 = newValue),
                            itemBuilder: (context, index) => Icon(
                              Icons.star_rounded,
                              color: FlutterFlowTheme.of(context).tertiary,
                            ),
                            direction: Axis.horizontal,
                            initialRating: _model.ratingBarValue5 ??= 1.0,
                            unratedColor: Colors.transparent,
                            itemCount: 5,
                            itemPadding:
                                EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                            itemSize: 10.0,
                            glowColor: FlutterFlowTheme.of(context).tertiary,
                          ),
                        ].divide(SizedBox(height: 4.0)),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            LinearPercentIndicator(
                              percent: valueOrDefault<double>(
                                functions.calculateRatingPercentage(
                                    widget!.parkingRow!.stars5!,
                                    widget!.parkingRow!.stars1!,
                                    widget!.parkingRow!.stars2!,
                                    widget!.parkingRow!.stars3!,
                                    widget!.parkingRow!.stars4!,
                                    widget!.parkingRow!.stars5!),
                                0.0,
                              ),
                              lineHeight: 4.0,
                              animation: true,
                              animateFromLastPercent: true,
                              progressColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).buttons,
                              barRadius: Radius.circular(10.0),
                              padding: EdgeInsets.zero,
                            ),
                            LinearPercentIndicator(
                              percent: valueOrDefault<double>(
                                functions.calculateRatingPercentage(
                                    widget!.parkingRow!.stars4!,
                                    widget!.parkingRow!.stars1!,
                                    widget!.parkingRow!.stars2!,
                                    widget!.parkingRow!.stars3!,
                                    widget!.parkingRow!.stars4!,
                                    widget!.parkingRow!.stars5!),
                                0.0,
                              ),
                              lineHeight: 4.0,
                              animation: true,
                              animateFromLastPercent: true,
                              progressColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).buttons,
                              center: Text(
                                FFLocalizations.of(context).getText(
                                  '0tc0742s' /* 50% */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.roboto(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              barRadius: Radius.circular(10.0),
                              padding: EdgeInsets.zero,
                            ),
                            LinearPercentIndicator(
                              percent: valueOrDefault<double>(
                                functions.calculateRatingPercentage(
                                    widget!.parkingRow!.stars3!,
                                    widget!.parkingRow!.stars1!,
                                    widget!.parkingRow!.stars2!,
                                    widget!.parkingRow!.stars3!,
                                    widget!.parkingRow!.stars4!,
                                    widget!.parkingRow!.stars5!),
                                0.0,
                              ),
                              lineHeight: 4.0,
                              animation: true,
                              animateFromLastPercent: true,
                              progressColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).buttons,
                              center: Text(
                                FFLocalizations.of(context).getText(
                                  'uh6eg426' /* 50% */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.roboto(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              barRadius: Radius.circular(10.0),
                              padding: EdgeInsets.zero,
                            ),
                            LinearPercentIndicator(
                              percent: valueOrDefault<double>(
                                functions.calculateRatingPercentage(
                                    widget!.parkingRow!.stars2!,
                                    widget!.parkingRow!.stars1!,
                                    widget!.parkingRow!.stars2!,
                                    widget!.parkingRow!.stars3!,
                                    widget!.parkingRow!.stars4!,
                                    widget!.parkingRow!.stars5!),
                                0.0,
                              ),
                              lineHeight: 4.0,
                              animation: true,
                              animateFromLastPercent: true,
                              progressColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).buttons,
                              center: Text(
                                FFLocalizations.of(context).getText(
                                  'g529tf0w' /* 50% */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.roboto(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              barRadius: Radius.circular(10.0),
                              padding: EdgeInsets.zero,
                            ),
                            LinearPercentIndicator(
                              percent: valueOrDefault<double>(
                                functions.calculateRatingPercentage(
                                    widget!.parkingRow!.stars1!,
                                    widget!.parkingRow!.stars1!,
                                    widget!.parkingRow!.stars2!,
                                    widget!.parkingRow!.stars3!,
                                    widget!.parkingRow!.stars4!,
                                    widget!.parkingRow!.stars5!),
                                0.0,
                              ),
                              lineHeight: 4.0,
                              animation: true,
                              animateFromLastPercent: true,
                              progressColor:
                                  FlutterFlowTheme.of(context).tertiary,
                              backgroundColor:
                                  FlutterFlowTheme.of(context).buttons,
                              center: Text(
                                FFLocalizations.of(context).getText(
                                  'mpwx6x05' /* 50% */,
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .headlineSmall
                                    .override(
                                      font: GoogleFonts.roboto(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineSmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineSmall
                                          .fontStyle,
                                    ),
                              ),
                              barRadius: Radius.circular(10.0),
                              padding: EdgeInsets.zero,
                            ),
                          ].divide(SizedBox(height: 11.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      '960y3ktl' /* Share your impressions */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.roboto(
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText(
                      'p3wlf3ji' /* Your opinion is important to u... */,
                    ),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.roboto(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) => FFButtonWidget(
                            onPressed: AppConfig.current.integrationReadOnly
                                ? null
                                : () async {
                                    if (FFAppState().isGuest == true) {
                                      await showDialog(
                                        barrierColor:
                                            FlutterFlowTheme.of(context)
                                                .overlay,
                                        context: context,
                                        builder: (dialogContext) {
                                          return Dialog(
                                            elevation: 0,
                                            insetPadding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            alignment: AlignmentDirectional(
                                                    0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                            child: GuestDialogWidget(),
                                          );
                                        },
                                      );

                                      return;
                                    }
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      barrierColor:
                                          FlutterFlowTheme.of(context).overlay,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding:
                                              MediaQuery.viewInsetsOf(context),
                                          child: ReportCreateWidget(
                                            parkingId: widget!.parkingRow!.id!,
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  },
                            text: FFLocalizations.of(context).getText(
                              '2jy1g9cx' /* Report a problem */,
                            ),
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              textStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).error,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Builder(
                          builder: (context) => FFButtonWidget(
                            onPressed: AppConfig.current.integrationReadOnly ||
                                    functions.hasUserReviewed(
                                        containerViewReviewsWithUsersRowList
                                            .map((e) => e.userId)
                                            .withoutNulls
                                            .toList(),
                                        currentUserUid)
                                ? null
                                : () async {
                                    if (FFAppState().isGuest == true) {
                                      await showDialog(
                                        barrierColor:
                                            FlutterFlowTheme.of(context)
                                                .overlay,
                                        context: context,
                                        builder: (dialogContext) {
                                          return Dialog(
                                            elevation: 0,
                                            insetPadding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            alignment: AlignmentDirectional(
                                                    0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
                                            child: GuestDialogWidget(),
                                          );
                                        },
                                      );

                                      return;
                                    }
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      enableDrag: false,
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding:
                                              MediaQuery.viewInsetsOf(context),
                                          child: ReviewCreateWidget(
                                            parkingId: widget!.parkingRow!.id!,
                                          ),
                                        );
                                      },
                                    ).then((value) => safeSetState(() {}));
                                  },
                            text: FFLocalizations.of(context).getText(
                              'ms3fkz4k' /* Leave a review */,
                            ),
                            options: FFButtonOptions(
                              height: 40.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).info,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(12.0),
                              disabledColor:
                                  FlutterFlowTheme.of(context).inactiveButton,
                              disabledTextColor:
                                  FlutterFlowTheme.of(context).inactiveText,
                            ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(width: 8.0)),
                  ),
                ].divide(SizedBox(height: 8.0)),
              ),
              Align(
                alignment: AlignmentDirectional(-1.0, 0.0),
                child: Text(
                  FFLocalizations.of(context).getText(
                    '3ezk7f6o' /* All reviews */,
                  ),
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                      ),
                ),
              ),
              Builder(
                builder: (context) {
                  if (containerViewReviewsWithUsersRowList.length > 0) {
                    return Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 60.0),
                      child: Builder(
                        builder: (context) {
                          final reviews =
                              containerViewReviewsWithUsersRowList.toList();

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            itemCount: reviews.length,
                            itemBuilder: (context, reviewsIndex) {
                              final reviewsItem = reviews[reviewsIndex];
                              return ReviewCardParkingDetailsWidget(
                                key: Key(
                                    'Key7hq_${reviewsIndex}_of_${reviews.length}'),
                                reviewRow: reviewsItem,
                              );
                            },
                          );
                        },
                      ),
                    );
                  } else {
                    return AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(0.0),
                              child: SvgPicture.asset(
                                'assets/images/star.fill.svg',
                                width: 96.0,
                                height: 96.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Text(
                              FFLocalizations.of(context).getText(
                                'eb2hek18' /* There are no reviews yet */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    );
                  }
                },
              ),
            ].divide(SizedBox(height: 16.0)),
          ),
        );
      },
    );
  }
}
