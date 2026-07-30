import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/core/config/app_config.dart';
import '/features/favorites/application/favorites_controller.dart';
import '/features/parking_details/data/parking_details_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/parkings_details/info_tab/info_tab_widget.dart';
import '/parkings_details/photos_tab/photos_tab_widget.dart';
import '/parkings_details/reviews_tab/reviews_tab_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import '/subscription/subscription_dialog/subscription_dialog_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'parking_sheet_drag_handle.dart';
import 'parking_sheet_route_controller.dart';
import 'parkings_details_model.dart';
export 'parkings_details_model.dart';

class ParkingsDetailsWidget extends StatefulWidget {
  const ParkingsDetailsWidget({
    super.key,
    required this.parkingId,
  });

  final String? parkingId;

  @override
  State<ParkingsDetailsWidget> createState() => _ParkingsDetailsWidgetState();
}

class _ParkingsDetailsWidgetState extends State<ParkingsDetailsWidget> {
  late ParkingsDetailsModel _model;
  final _favoriteToggleController = FavoriteToggleController();
  final _parkingDetailsService = ParkingDetailsService();
  final _sheetRouteController = ParkingSheetRouteController();

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ParkingsDetailsModel());
    _model.parkingDetailsFuture = _parkingDetailsService.getParkingDetails(
      parkingId: widget.parkingId,
    );
    _favoriteToggleController.addListener(_onFavoriteToggleStateChanged);

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _favoriteToggleController.load(
        parkingId: widget.parkingId,
        userId: currentUserUid,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _favoriteToggleController.removeListener(_onFavoriteToggleStateChanged);
    _favoriteToggleController.dispose();
    _model.maybeDispose();

    super.dispose();
  }

  void _onFavoriteToggleStateChanged() {
    if (mounted) {
      safeSetState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant ParkingsDetailsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parkingId != oldWidget.parkingId) {
      _model.parkingDetailsFuture = _parkingDetailsService.getParkingDetails(
        parkingId: widget.parkingId,
      );
      _favoriteToggleController.load(
        parkingId: widget.parkingId,
        userId: currentUserUid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final canToggleFavorite =
        AppConfig.current.canPerformWrite(AppWriteOperation.favoriteToggle);
    final canUseFavoriteButton =
        canToggleFavorite && !_favoriteToggleController.state.isUpdating;

    return SingleChildScrollView(
      controller: _model.sheetScrollController,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              _dismissSheet();
            },
            child: Container(
              width: double.infinity,
              height: 300.0,
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
          FutureBuilder<ParkingDetails?>(
            future: _model.parkingDetailsFuture,
            builder: (context, snapshot) {
              // Customize what your widget looks like when it's loading.
              if (snapshot.connectionState != ConnectionState.done ||
                  snapshot.hasError) {
                return _buildParkingDetailsLoading(context);
              }
              final mainContainerViewFullParkingDetailsRow = snapshot.data;

              return SafeArea(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSheetHandle(context),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 16.0),
                          child: Builder(
                            builder: (context) {
                              if (mainContainerViewFullParkingDetailsRow
                                      ?.allPhotos !=
                                  null) {
                                return Builder(
                                  builder: (context) {
                                    final photos =
                                        mainContainerViewFullParkingDetailsRow
                                                ?.allPhotos
                                                ?.toList() ??
                                            [];

                                    return Container(
                                      width: double.infinity,
                                      height: 210.0,
                                      child: Stack(
                                        children: [
                                          PageView.builder(
                                            controller:
                                                _model.pageViewController ??=
                                                    PageController(
                                                        initialPage: max(
                                                            0,
                                                            min(
                                                                0,
                                                                photos.length -
                                                                    1))),
                                            scrollDirection: Axis.horizontal,
                                            itemCount: photos.length,
                                            itemBuilder:
                                                (context, photosIndex) {
                                              final photosItem =
                                                  photos[photosIndex];
                                              return InkWell(
                                                splashColor: Colors.transparent,
                                                focusColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                highlightColor:
                                                    Colors.transparent,
                                                onTap: () async {
                                                  context.pushNamed(
                                                    PhotoDetailedWidget
                                                        .routeName,
                                                    queryParameters: {
                                                      'photoPath':
                                                          serializeParam(
                                                        photosItem.url
                                                            .toString(),
                                                        ParamType.String,
                                                      ),
                                                      'index': serializeParam(
                                                        photosIndex,
                                                        ParamType.int,
                                                      ),
                                                      'address': serializeParam(
                                                        mainContainerViewFullParkingDetailsRow
                                                            ?.address,
                                                        ParamType.String,
                                                      ),
                                                      'photoCount':
                                                          serializeParam(
                                                        mainContainerViewFullParkingDetailsRow
                                                            ?.photosCount,
                                                        ParamType.int,
                                                      ),
                                                      'photoRef':
                                                          serializeParam(
                                                        photosItem.url
                                                            .toString(),
                                                        ParamType.String,
                                                      ),
                                                      'data': serializeParam(
                                                        photosItem.dateDisplay
                                                            .toString(),
                                                        ParamType.String,
                                                      ),
                                                    }.withoutNulls,
                                                  );
                                                },
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  child: Image.network(
                                                    photosItem.url.toString(),
                                                    width: double.infinity,
                                                    height: 194.0,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          Align(
                                            alignment:
                                                AlignmentDirectional(0.0, 0.8),
                                            child: smooth_page_indicator
                                                .SmoothPageIndicator(
                                              controller: _model
                                                      .pageViewController ??=
                                                  PageController(
                                                      initialPage: max(
                                                          0,
                                                          min(
                                                              0,
                                                              photos.length -
                                                                  1))),
                                              count: photos.length,
                                              axisDirection: Axis.horizontal,
                                              onDotClicked: (i) async {
                                                await _model.pageViewController!
                                                    .animateToPage(
                                                  i,
                                                  duration: Duration(
                                                      milliseconds: 500),
                                                  curve: Curves.ease,
                                                );
                                                safeSetState(() {});
                                              },
                                              effect: smooth_page_indicator
                                                  .SlideEffect(
                                                spacing: 8.0,
                                                radius: 8.0,
                                                dotWidth: 8.0,
                                                dotHeight: 8.0,
                                                dotColor:
                                                    FlutterFlowTheme.of(context)
                                                        .thertaryText,
                                                activeDotColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                paintStyle: PaintingStyle.fill,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return Container(
                                  width: double.infinity,
                                  height: 194.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Icon(
                                    Icons.no_photography,
                                    color:
                                        FlutterFlowTheme.of(context).checkBoxes,
                                    size: 100.0,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Builder(
                                  builder: (context) => FFButtonWidget(
                                    onPressed: () async {
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
                                              backgroundColor:
                                                  Colors.transparent,
                                              alignment:
                                                  AlignmentDirectional(0.0, 0.0)
                                                      .resolve(
                                                          Directionality.of(
                                                              context)),
                                              child: GuestDialogWidget(),
                                            );
                                          },
                                        );

                                        return;
                                      }
                                      if (FFAppState().premiumUntil != null) {
                                        await actions.openGoogleMapsRoute(
                                          functions.convertToLatLng(
                                              mainContainerViewFullParkingDetailsRow!
                                                  .latitude!,
                                              mainContainerViewFullParkingDetailsRow!
                                                  .longitude!),
                                        );
                                      } else {
                                        await showDialog(
                                          barrierColor:
                                              FlutterFlowTheme.of(context)
                                                  .overlay,
                                          context: context,
                                          builder: (dialogContext) {
                                            return Dialog(
                                              elevation: 0,
                                              insetPadding: EdgeInsets.zero,
                                              backgroundColor:
                                                  Colors.transparent,
                                              alignment:
                                                  AlignmentDirectional(0.0, 0.0)
                                                      .resolve(
                                                          Directionality.of(
                                                              context)),
                                              child: SubscriptionDialogWidget(
                                                lat:
                                                    mainContainerViewFullParkingDetailsRow!
                                                        .latitude!,
                                                lng:
                                                    mainContainerViewFullParkingDetailsRow!
                                                        .longitude!,
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    },
                                    text: FFLocalizations.of(context).getText(
                                      'yt9sz7yw' /* Set a route */,
                                    ),
                                    icon: Icon(
                                      FFIcons.krouting,
                                      size: 24.0,
                                    ),
                                    options: FFButtonOptions(
                                      height: 56.0,
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 0.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      iconColor:
                                          FlutterFlowTheme.of(context).info,
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            font: GoogleFonts.roboto(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .info,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) => InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: !canUseFavoriteButton
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
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  alignment:
                                                      AlignmentDirectional(
                                                              0.0, 0.0)
                                                          .resolve(
                                                    Directionality.of(context),
                                                  ),
                                                  child: GuestDialogWidget(),
                                                );
                                              },
                                            );
                                            return;
                                          }

                                          final didUpdate =
                                              await _favoriteToggleController
                                                  .toggle(
                                            parkingId: widget.parkingId,
                                            userId: currentUserUid,
                                          );
                                          if (!didUpdate) {
                                            if (!context.mounted) {
                                              return;
                                            }
                                            showSnackbar(
                                              context,
                                              'Could not update favorites. Please try again.',
                                            );
                                          }
                                        },
                                  child: Container(
                                    width: 56.0,
                                    height: 56.0,
                                    decoration: BoxDecoration(
                                      color: !canUseFavoriteButton
                                          ? FlutterFlowTheme.of(context)
                                              .inactiveButton
                                          : FlutterFlowTheme.of(context)
                                              .buttons,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Builder(
                                        builder: (context) {
                                          if (_favoriteToggleController
                                                  .state.isFavorite ==
                                              true) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                              child: SvgPicture.asset(
                                                'assets/images/favorite_blue.svg',
                                                width: 24.0,
                                                height: 24.0,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          } else {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(0.0),
                                              child: SvgPicture.asset(
                                                'assets/images/faavorite_white.svg',
                                                width: 24.0,
                                                height: 24.0,
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Builder(
                                builder: (context) => InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
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
                                    if (mainContainerViewFullParkingDetailsRow
                                            ?.allPhotos !=
                                        null) {
                                      await Share.share(
                                        'https://js-truck-park.web.app/deeplink.html?targetParkingId=${widget!.parkingId}&targetLat=${mainContainerViewFullParkingDetailsRow?.latitude?.toString()}&targetLng=${mainContainerViewFullParkingDetailsRow?.longitude?.toString()}',
                                        sharePositionOrigin:
                                            getWidgetBoundingBox(context),
                                      );
                                    } else {
                                      return;
                                    }
                                  },
                                  child: Container(
                                    width: 56.0,
                                    height: 56.0,
                                    decoration: BoxDecoration(
                                      color:
                                          FlutterFlowTheme.of(context).buttons,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(0.0),
                                        child: SvgPicture.asset(
                                          'assets/images/sheare.svg',
                                          width: 24.0,
                                          height: 24.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _selectTab(TabsToggle.info);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _model.activeTab == TabsToggle.info
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryBackground
                                        : FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 6.0, 16.0, 6.0),
                                    child: Text(
                                      FFLocalizations.of(context).getText(
                                        '67t6qqlw' /* Info */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: _model.activeTab ==
                                                    TabsToggle.info
                                                ? FlutterFlowTheme.of(context)
                                                    .primaryText
                                                : FlutterFlowTheme.of(context)
                                                    .inactiveTabText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _selectTab(TabsToggle.review);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _model.activeTab == TabsToggle.review
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryBackground
                                        : FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 6.0, 0.0, 6.0),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'ips08b2l' /* Reviews */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: _model.activeTab ==
                                                        TabsToggle.review
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .inactiveTabText,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.4,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  10.0, 2.0, 10.0, 2.0),
                                          child: Text(
                                            valueOrDefault<String>(
                                              mainContainerViewFullParkingDetailsRow
                                                  ?.reviewsCount
                                                  ?.toString(),
                                              '0',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 4.0)),
                                  ),
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  _selectTab(TabsToggle.photo);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _model.activeTab == TabsToggle.photo
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryBackground
                                        : FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16.0, 6.0, 0.0, 6.0),
                                        child: Text(
                                          FFLocalizations.of(context).getText(
                                            'xmtd8nx0' /* Photo */,
                                          ),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color: _model.activeTab ==
                                                        TabsToggle.photo
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText
                                                    : FlutterFlowTheme.of(
                                                            context)
                                                        .inactiveTabText,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.4,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  10.0, 2.0, 10.0, 2.0),
                                          child: Text(
                                            valueOrDefault<String>(
                                              mainContainerViewFullParkingDetailsRow
                                                  ?.photosCount
                                                  ?.toString(),
                                              '0',
                                            ),
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .accent1,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 4.0)),
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            return ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.sizeOf(context).height * 0.45,
                              ),
                              child: Builder(
                                builder: (context) {
                                  if (_model.activeTab == TabsToggle.info) {
                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 36.0),
                                        child: wrapWithModel(
                                          model: _model.infoTabModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: InfoTabWidget(
                                            parkingRow:
                                                mainContainerViewFullParkingDetailsRow!,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else if (_model.activeTab ==
                                      TabsToggle.review) {
                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 36.0),
                                        child: wrapWithModel(
                                          model: _model.reviewsTabModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ReviewsTabWidget(
                                            parkingRow:
                                                mainContainerViewFullParkingDetailsRow!,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Container(
                                      decoration: BoxDecoration(),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 0.0, 0.0, 36.0),
                                        child: wrapWithModel(
                                          model: _model.photosTabModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: PhotosTabWidget(
                                            parkingRow:
                                                mainContainerViewFullParkingDetailsRow!,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildParkingDetailsLoading(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.primaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(context),
              Container(
                width: double.infinity,
                height: 180.0,
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 18.0, 0.0, 0.0),
                child: Container(
                  width: 220.0,
                  height: 18.0,
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                child: Container(
                  width: 150.0,
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: theme.alternate,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 22.0, 0.0, 0.0),
                child: Center(
                  child: SizedBox(
                    width: 22.0,
                    height: 22.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetHandle(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ParkingSheetDragHandle(
      backgroundColor: theme.primaryBackground,
      handleColor: theme.divider,
      iconColor: theme.secondaryText,
      onDismiss: _dismissSheet,
    );
  }

  void _dismissSheet() {
    _sheetRouteController.dismiss(context);
  }

  void _selectTab(TabsToggle tab) {
    final controller = _model.sheetScrollController;
    _model.preservedSheetScrollOffset =
        controller?.hasClients == true ? controller!.offset : null;

    _model.activeTab = tab;
    safeSetState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final offset = _model.preservedSheetScrollOffset;
      final controller = _model.sheetScrollController;
      if (offset == null || controller?.hasClients != true) {
        return;
      }

      final boundedOffset = offset.clamp(
        controller!.position.minScrollExtent,
        controller.position.maxScrollExtent,
      );
      controller.jumpTo(boundedOffset);
    });
  }
}
