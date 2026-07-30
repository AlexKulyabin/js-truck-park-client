import '/backend/schema/enums/enums.dart';
import '/core/config/app_config.dart';
import '/features/parking_details/application/parking_favorite_controller.dart';
import '/features/parking_details/application/parking_details_controller.dart';
import '/features/parking_details/data/supabase_parking_favorite_repository.dart';
import '/features/parking_details/data/supabase_parking_details_repository.dart';
import '/features/parking_details/domain/parking_favorite_repository.dart';
import '/features/parking_details/domain/parking_details_repository.dart';
import '/features/parking_details/presentation/parking_details_links.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/parkings_details/info_tab/info_tab_widget.dart';
import '/parkings_details/photos_tab/photos_tab_widget.dart';
import '/parkings_details/reviews_tab/reviews_tab_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import '/subscription/subscription_dialog/subscription_dialog_widget.dart';
import 'dart:async';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'package:flutter/material.dart';
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
    this.detailsRepository,
    this.favoriteRepository,
  });

  final String? parkingId;
  final ParkingDetailsRepository? detailsRepository;
  final ParkingFavoriteRepository? favoriteRepository;

  static const loadingKey = Key('public-parking-details-loading');
  static const failureKey = Key('public-parking-details-failure');
  static const emptyKey = Key('public-parking-details-empty');
  static const scrollViewKey = Key('public-parking-details-scroll-view');
  static const dragHandleKey = Key('public-parking-details-drag-handle');
  static const photoGalleryKey = Key('public-parking-details-photo-gallery');
  static const favoriteButtonKey = Key('public-parking-favorite-button');
  static const favoriteUpdatingKey = Key('public-parking-favorite-updating');

  @override
  State<ParkingsDetailsWidget> createState() => _ParkingsDetailsWidgetState();
}

class _ParkingsDetailsWidgetState extends State<ParkingsDetailsWidget> {
  late ParkingsDetailsModel _model;
  late final ParkingDetailsController _controller;
  late final ParkingFavoriteController _favoriteController;
  final ScrollController _detailsScrollController = ScrollController();
  final ParkingSheetRouteController _sheetRouteController =
      ParkingSheetRouteController();
  double? _preservedSheetScrollOffset;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ParkingsDetailsModel());
    _controller = ParkingDetailsController(
      repository:
          widget.detailsRepository ?? SupabaseParkingDetailsRepository(),
      parkingId: widget.parkingId ?? '',
    )..addListener(_onDetailsStateChanged);
    _favoriteController = ParkingFavoriteController(
      repository:
          widget.favoriteRepository ?? SupabaseParkingFavoriteRepository(),
      parkingId: widget.parkingId ?? '',
    )..addListener(_onFavoriteStateChanged);
    unawaited(_controller.loadDetails());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  void _onDetailsStateChanged() {
    final details = _controller.state.details;
    if (details != null) {
      _favoriteController.initialize(details.isFavorited);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onFavoriteStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showFavoriteFailure(ParkingFavoriteFailureKind? kind) {
    final isRussian = Localizations.localeOf(context).languageCode == 'ru';
    final message = kind == ParkingFavoriteFailureKind.unauthenticated
        ? (isRussian
            ? 'Сессия завершена. Войдите снова.'
            : 'Your session has expired. Please sign in again.')
        : (isRussian
            ? 'Не удалось обновить избранное. Попробуйте ещё раз.'
            : 'Unable to update favorites. Please try again.');
    showSnackbar(context, message);
  }

  void _handlePhotoVerticalDrag(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null || !_detailsScrollController.hasClients) {
      return;
    }

    final position = _detailsScrollController.position;
    final target = (position.pixels - delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _detailsScrollController.jumpTo(target);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onDetailsStateChanged)
      ..dispose();
    _favoriteController
      ..removeListener(_onFavoriteStateChanged)
      ..dispose();
    _detailsScrollController.dispose();
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final canToggleFavorite =
        AppConfig.current.canPerformWrite(AppWriteOperation.favoriteToggle);
    final canUseFavoriteButton = canToggleFavorite &&
        _favoriteController.state.phase !=
            ParkingFavoriteMutationPhase.updating;

    return SingleChildScrollView(
      key: ParkingsDetailsWidget.scrollViewKey,
      controller: _detailsScrollController,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              height: 300.0,
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final state = _controller.state;
              if (state.detailsPhase == ParkingDetailsLoadPhase.idle ||
                  state.detailsPhase == ParkingDetailsLoadPhase.loading) {
                return _buildParkingDetailsLoading(context);
              }
              if (state.detailsPhase == ParkingDetailsLoadPhase.failure) {
                return InkWell(
                  key: ParkingsDetailsWidget.failureKey,
                  onTap: () => unawaited(_controller.loadDetails()),
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
              final details = state.details;
              if (details == null) {
                return SizedBox(
                  key: ParkingsDetailsWidget.emptyKey,
                  height: 194.0,
                  child: Icon(
                    Icons.location_off_outlined,
                    color: FlutterFlowTheme.of(context).checkBoxes,
                    size: 72.0,
                  ),
                );
              }

              return SafeArea(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height,
                  ),
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
                          child: GestureDetector(
                            key: ParkingsDetailsWidget.photoGalleryKey,
                            behavior: HitTestBehavior.translucent,
                            onVerticalDragUpdate: _handlePhotoVerticalDrag,
                            child: Builder(
                              builder: (context) {
                                if (details.photos != null) {
                                  return Builder(
                                    builder: (context) {
                                      final photos = details.photos ?? const [];

                                      return Container(
                                        width: double.infinity,
                                        height: 210.0,
                                        child: Stack(
                                          children: [
                                            PageView.builder(
                                              controller: _model
                                                      .pageViewController ??=
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
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    context.pushNamed(
                                                      PhotoDetailedWidget
                                                          .routeName,
                                                      queryParameters: {
                                                        'photoPath':
                                                            serializeParam(
                                                          photosItem.url,
                                                          ParamType.String,
                                                        ),
                                                        'index': serializeParam(
                                                          photosIndex,
                                                          ParamType.int,
                                                        ),
                                                        'address':
                                                            serializeParam(
                                                          details.address,
                                                          ParamType.String,
                                                        ),
                                                        'photoCount':
                                                            serializeParam(
                                                          details.photosCount,
                                                          ParamType.int,
                                                        ),
                                                        'photoRef':
                                                            serializeParam(
                                                          photosItem.url,
                                                          ParamType.String,
                                                        ),
                                                        'data': serializeParam(
                                                          photosItem.photoDate,
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
                                                      photosItem.url,
                                                      width: double.infinity,
                                                      height: 194.0,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) =>
                                                          Icon(
                                                        Icons
                                                            .no_photography_outlined,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                          context,
                                                        ).checkBoxes,
                                                        size: 72.0,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.8),
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
                                                  await _model
                                                      .pageViewController!
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
                                                  dotColor: FlutterFlowTheme.of(
                                                          context)
                                                      .thertaryText,
                                                  activeDotColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondaryBackground,
                                                  paintStyle:
                                                      PaintingStyle.fill,
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
                                      color: FlutterFlowTheme.of(context)
                                          .checkBoxes,
                                      size: 100.0,
                                    ),
                                  );
                                }
                              },
                            ),
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
                                            details.latitude!,
                                            details.longitude!,
                                          ),
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
                                                lat: details.latitude!,
                                                lng: details.longitude!,
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
                                  key: ParkingsDetailsWidget.favoriteButtonKey,
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
                                          final outcome =
                                              await _favoriteController
                                                  .toggle();
                                          if (outcome ==
                                                  ParkingFavoriteToggleOutcome
                                                      .failed &&
                                              mounted) {
                                            _showFavoriteFailure(
                                              _favoriteController
                                                  .state.failureKind,
                                            );
                                          }
                                        },
                                  child: Container(
                                    width: 56.0,
                                    height: 56.0,
                                    decoration: BoxDecoration(
                                      color: !canToggleFavorite
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
                                          final favoriteState =
                                              _favoriteController.state;
                                          if (favoriteState.phase ==
                                              ParkingFavoriteMutationPhase
                                                  .updating) {
                                            return SizedBox(
                                              key: ParkingsDetailsWidget
                                                  .favoriteUpdatingKey,
                                              width: 24.0,
                                              height: 24.0,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.0,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                                ),
                                              ),
                                            );
                                          }
                                          if (favoriteState.isFavorite) {
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
                                    if (details.photos != null) {
                                      await Share.share(
                                        buildParkingShareUrl(details),
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
                                              details.reviewsCount?.toString(),
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
                                              details.photosCount?.toString(),
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
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.sizeOf(context).height * 0.45,
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
                                      updateCallback: () => safeSetState(() {}),
                                      child: InfoTabWidget(
                                        details: details,
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
                                      updateCallback: () => safeSetState(() {}),
                                      child: ReviewsTabWidget(
                                        details: details,
                                        detailsController: _controller,
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
                                      updateCallback: () => safeSetState(() {}),
                                      child: PhotosTabWidget(
                                        details: details,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
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
        key: ParkingsDetailsWidget.loadingKey,
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
      key: ParkingsDetailsWidget.dragHandleKey,
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
    _preservedSheetScrollOffset = _detailsScrollController.hasClients
        ? _detailsScrollController.offset
        : null;

    _model.activeTab = tab;
    safeSetState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_detailsScrollController.hasClients) {
        return;
      }
      final offset = _preservedSheetScrollOffset;
      if (offset == null) {
        return;
      }

      final position = _detailsScrollController.position;
      _detailsScrollController.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }
}
