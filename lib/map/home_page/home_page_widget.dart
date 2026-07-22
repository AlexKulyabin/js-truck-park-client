import '/backend/api_requests/api_calls.dart';
import '/core/config/app_config.dart';
import '/create_parking/create_parking_dialog/create_parking_dialog_widget.dart';
import '/filter/filter/filter_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/parkings_details/parkings_details/parkings_details_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({
    super.key,
    this.targetParkingId,
    this.targetLat,
    this.targetLng,
  });

  final String? targetParkingId;
  final double? targetLat;
  final double? targetLng;

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (AppConfig.current.integrationReadOnly) {
        return;
      }
      if (FFAppState().isGuest == true) {
        return;
      }
      if (widget!.targetParkingId != null && widget!.targetParkingId != '') {
        await showModalBottomSheet(
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          enableDrag: false,
          context: context,
          builder: (context) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Padding(
                padding: MediaQuery.viewInsetsOf(context),
                child: ParkingsDetailsWidget(
                  parkingId: widget!.targetParkingId!,
                ),
              ),
            );
          },
        ).then((value) => safeSetState(() {}));
      }
      _model.fetchPremiumExpirationDateOut =
          await actions.fetchPremiumExpirationDate();
      FFAppState().premiumUntil = _model.fetchPremiumExpirationDateOut;
      safeSetState(() {});
    });

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    if (currentUserLocationValue == null) {
      return Container(
        color: FlutterFlowTheme.of(context).primaryBackground,
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Stack(
          alignment: AlignmentDirectional(0.0, 1.0),
          children: [
            Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Stack(
                      alignment: AlignmentDirectional(1.0, 1.0),
                      children: [
                        Builder(
                          builder: (context) => Container(
                            width: MediaQuery.sizeOf(context).width * 1.0,
                            height: MediaQuery.sizeOf(context).height * 1.0,
                            child: custom_widgets.CustomGoogleMap(
                              width: MediaQuery.sizeOf(context).width * 1.0,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              initialLat: widget!.targetLat != null
                                  ? widget!.targetLat!
                                  : functions.getLat(currentUserLocationValue),
                              initialLng: widget!.targetLng != null
                                  ? widget!.targetLng!
                                  : functions.getLng(currentUserLocationValue),
                              initialZoom: 13.0,
                              allowGestures: true,
                              markerIconPath:
                                  'https://jckksrcdmhtafwbimzov.supabase.co/storage/v1/object/public/assets/icnLocation.png',
                              markerSize: 30,
                              markerData: _model.parkingsOnMap,
                              centerToMoveTo: _model.searchCoord,
                              isDarkMode: Theme.of(context).brightness ==
                                  Brightness.dark,
                              clusterSize: 120,
                              onMarkerTap: (markerId) async {
                                if (AppConfig.current.integrationReadOnly) {
                                  return;
                                }
                                FFAppState().isMapUnLocked = false;
                                safeSetState(() {});
                                await showModalBottomSheet(
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  enableDrag: false,
                                  context: context,
                                  builder: (context) {
                                    return GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      },
                                      child: Padding(
                                        padding:
                                            MediaQuery.viewInsetsOf(context),
                                        child: ParkingsDetailsWidget(
                                          parkingId: markerId,
                                        ),
                                      ),
                                    );
                                  },
                                ).then((value) => safeSetState(() {}));
                              },
                              onClusterTap: (lat, lng) async {},
                              onCameraIdle:
                                  (minLat, minLng, maxLat, maxLng, zoom) async {
                                _model.latMin = minLat;
                                _model.latMax = maxLat;
                                _model.lngMin = minLng;
                                _model.lngMax = maxLng;
                                _model.currentZoom = zoom;
                                safeSetState(() {});
                                _model.getFilteredParkings =
                                    await GetFilteredParkingsCall.call(
                                  minLat: minLat,
                                  maxLat: maxLat,
                                  minLng: minLng,
                                  maxLng: maxLng,
                                  isActive: FFAppState().isFilterApplied,
                                  radius: FFAppState().isFilterShowNearest
                                      ? functions.getMetersFromIndex(
                                          FFAppState().filterRadius)
                                      : 0.0,
                                  lat: (minLat + maxLat) / 2,
                                  lng: (minLng + maxLng) / 2,
                                  minCap: FFAppState().filterCapacityFrom,
                                  maxCap: FFAppState().filterCapacityTo,
                                  gas: FFAppState().isFilterHasGas,
                                  shower: FFAppState().isFilterHasShower,
                                  laundry: FFAppState().isFilterHasLaundry,
                                  hotel: FFAppState().isFilterHasHotel,
                                  shop: FFAppState().isFilterHasShop,
                                  recreation:
                                      FFAppState().isFilterHasRecreation,
                                  zoom: zoom,
                                );

                                if ((_model.getFilteredParkings?.succeeded ??
                                    true)) {
                                  _model.parkingsOnMap =
                                      (_model.getFilteredParkings?.jsonBody ??
                                          '');
                                  safeSetState(() {});
                                }

                                safeSetState(() {});
                              },
                              onLongPress: (longPressedPoint) async {
                                if (AppConfig.current.integrationReadOnly) {
                                  return;
                                }
                                FFAppState().tempLat =
                                    functions.getLat(longPressedPoint);
                                FFAppState().tempLng =
                                    functions.getLng(longPressedPoint);
                                safeSetState(() {});
                                _model.getAddressFromCoordsRes =
                                    await GetAddressFromCoordsCall.call(
                                  lat: FFAppState().tempLat,
                                  lng: FFAppState().tempLng,
                                );

                                if ((_model
                                        .getAddressFromCoordsRes?.succeeded ??
                                    true)) {
                                  FFAppState().tempAddress = getJsonField(
                                    (_model.getAddressFromCoordsRes?.jsonBody ??
                                        ''),
                                    r'''$.results[0].formatted_address''',
                                  ).toString();
                                  safeSetState(() {});
                                }
                                FFAppState().isMapUnLocked = false;
                                safeSetState(() {});
                                await showDialog(
                                  barrierColor: Color(0x66000000),
                                  context: context,
                                  builder: (dialogContext) {
                                    return Dialog(
                                      elevation: 0,
                                      insetPadding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      alignment: AlignmentDirectional(0.0, 0.0)
                                          .resolve(Directionality.of(context)),
                                      child: GestureDetector(
                                        onTap: () {
                                          FocusScope.of(dialogContext)
                                              .unfocus();
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                        child: CreateParkingDialogWidget(),
                                      ),
                                    );
                                  },
                                ).then((value) => safeSetState(() => _model
                                    .closeCreateParkingDialogOut = value));

                                if (_model.closeCreateParkingDialogOut!) {
                                  FFAppState().isMapUnLocked = true;
                                  safeSetState(() {});
                                }

                                safeSetState(() {});
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: AlignmentDirectional(1.0, -1.0),
                      child: Builder(
                        builder: (context) => Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 0.0, 24.0),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              if (FFAppState().isGuest == true) {
                                await showDialog(
                                  barrierColor:
                                      FlutterFlowTheme.of(context).overlay,
                                  context: context,
                                  builder: (dialogContext) {
                                    return Dialog(
                                      elevation: 0,
                                      insetPadding: EdgeInsets.zero,
                                      backgroundColor: Colors.transparent,
                                      alignment: AlignmentDirectional(0.0, 0.0)
                                          .resolve(Directionality.of(context)),
                                      child: GestureDetector(
                                        onTap: () {
                                          FocusScope.of(dialogContext)
                                              .unfocus();
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                        child: GuestDialogWidget(),
                                      ),
                                    );
                                  },
                                );

                                return;
                              }

                              context.pushNamed(CreateParkingWidget.routeName);
                            },
                            child: Material(
                              color: Colors.transparent,
                              elevation: 1.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99.0),
                              ),
                              child: Container(
                                width: 46.0,
                                height: 46.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).info,
                                  borderRadius: BorderRadius.circular(99.0),
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: FlutterFlowTheme.of(context).primary,
                                  size: 24.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(1.0, 1.0),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            0.0, 0.0, 16.0, 24.0),
                        child: InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            currentUserLocationValue =
                                await getCurrentUserLocation(
                                    defaultLocation: LatLng(0.0, 0.0));
                            await Future.delayed(
                              Duration(
                                milliseconds: 100,
                              ),
                            );
                            _model.searchCoord = currentUserLocationValue;
                            safeSetState(() {});
                          },
                          child: Material(
                            color: Colors.transparent,
                            elevation: 1.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99.0),
                            ),
                            child: Container(
                              width: 46.0,
                              height: 46.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).info,
                                borderRadius: BorderRadius.circular(99.0),
                              ),
                              child: Icon(
                                Icons.my_location_outlined,
                                color: FlutterFlowTheme.of(context).primary,
                                size: 24.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Stack(
                      alignment: AlignmentDirectional(0.0, 1.0),
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 8.0, 0.0, 8.0),
                              child: GestureDetector(
                                onVerticalDragEnd: (details) async {
                                  _model.isSearching = false;
                                  safeSetState(() {});
                                  safeSetState(() {
                                    _model.textController?.clear();
                                  });
                                },
                                child: Container(
                                  width: 36.0,
                                  height: 5.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).divider,
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                              ),
                            ),
                            if (_model.isSearching)
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 0.0, 16.0, 0.0),
                                  child: Builder(
                                    builder: (context) {
                                      final parkingsItem =
                                          _model.searchResults.toList();

                                      return ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount: parkingsItem.length,
                                        separatorBuilder: (_, __) =>
                                            SizedBox(height: 2.0),
                                        itemBuilder:
                                            (context, parkingsItemIndex) {
                                          final parkingsItemItem =
                                              parkingsItem[parkingsItemIndex];
                                          return GestureDetector(
                                            onTap: () async {
                                              _model.searchCoord =
                                                  functions.convertToLatLng(
                                                      getJsonField(
                                                        parkingsItemItem,
                                                        r'''$.lat''',
                                                      ),
                                                      getJsonField(
                                                        parkingsItemItem,
                                                        r'''$.lng''',
                                                      ));
                                              _model.isSearching = false;
                                              _model.isMapLocked = false;
                                              safeSetState(() {});
                                              safeSetState(() {
                                                _model.textController?.clear();
                                              });
                                              await actions.hideKeyboard();
                                              if (AppConfig.current
                                                  .integrationReadOnly) {
                                                return;
                                              }
                                              await showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                enableDrag: false,
                                                context: context,
                                                builder: (context) {
                                                  return GestureDetector(
                                                    onTap: () {
                                                      FocusScope.of(context)
                                                          .unfocus();
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();
                                                    },
                                                    child: Padding(
                                                      padding: MediaQuery
                                                          .viewInsetsOf(
                                                              context),
                                                      child:
                                                          ParkingsDetailsWidget(
                                                        parkingId: getJsonField(
                                                          parkingsItemItem,
                                                          r'''$.id''',
                                                        ).toString(),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ).then((value) =>
                                                  safeSetState(() {}));
                                            },
                                            onVerticalDragEnd: (details) async {
                                              safeSetState(() {
                                                _model.textController?.clear();
                                              });
                                              _model.isSearching = false;
                                              safeSetState(() {});
                                            },
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  valueOrDefault<String>(
                                                    getJsonField(
                                                      parkingsItemItem,
                                                      r'''$.address''',
                                                    )?.toString(),
                                                    'No address',
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.roboto(
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
                                                        fontSize: 17.0,
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
                                                      ),
                                                ),
                                                Divider(
                                                  thickness: 2.0,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .checksFormsButtons,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            Align(
                              alignment: AlignmentDirectional(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          16.0, 0.0, 16.0, 20.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 40.0,
                                              decoration: BoxDecoration(),
                                              child: Container(
                                                width: double.infinity,
                                                child: TextFormField(
                                                  controller:
                                                      _model.textController,
                                                  focusNode:
                                                      _model.textFieldFocusNode,
                                                  onChanged: (_) =>
                                                      EasyDebounce.debounce(
                                                    '_model.textController',
                                                    Duration(milliseconds: 500),
                                                    () async {
                                                      if (_model.textController
                                                                  .text !=
                                                              null &&
                                                          _model.textController
                                                                  .text !=
                                                              '') {
                                                        _model.getFilteredParkingsOut =
                                                            await GetFilteredParkingsCall
                                                                .call(
                                                          searchQuery: functions
                                                              .textToLower(_model
                                                                  .textController
                                                                  .text),
                                                          isActive: FFAppState()
                                                              .isFilterApplied,
                                                          zoom: 20.0,
                                                          radius: FFAppState()
                                                                  .isFilterShowNearest
                                                              ? functions
                                                                  .getMetersFromIndex(
                                                                      FFAppState()
                                                                          .filterRadius)
                                                              : 0.0,
                                                          lat: ((_model
                                                                      .latMin!) +
                                                                  (_model
                                                                      .latMax!)) /
                                                              2,
                                                          lng: ((_model
                                                                      .lngMin!) +
                                                                  (_model
                                                                      .lngMax!)) /
                                                              2,
                                                          minLat: _model.latMin,
                                                          maxLat: _model.latMax,
                                                          minLng: _model.lngMin,
                                                          maxLng: _model.lngMax,
                                                          minCap: FFAppState()
                                                              .filterCapacityFrom,
                                                          maxCap: FFAppState()
                                                              .filterCapacityTo,
                                                          gas: FFAppState()
                                                              .isFilterHasGas,
                                                          shower: FFAppState()
                                                              .isFilterHasShower,
                                                          laundry: FFAppState()
                                                              .isFilterHasLaundry,
                                                          hotel: FFAppState()
                                                              .isFilterHasHotel,
                                                          shop: FFAppState()
                                                              .isFilterHasShop,
                                                          recreation: FFAppState()
                                                              .isFilterHasRecreation,
                                                        );

                                                        _model.searchResults =
                                                            (_model.getFilteredParkingsOut
                                                                        ?.jsonBody ??
                                                                    '')
                                                                .toList()
                                                                .cast<
                                                                    dynamic>();
                                                        _model.isSearching =
                                                            true;
                                                        safeSetState(() {});
                                                      } else {
                                                        _model.isSearching =
                                                            false;
                                                        _model.searchResults =
                                                            [];
                                                        safeSetState(() {});
                                                      }

                                                      safeSetState(() {});
                                                    },
                                                  ),
                                                  autofocus: false,
                                                  enabled: true,
                                                  obscureText: false,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    labelStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .roboto(
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                              ),
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .searchMapsHinit,
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelMedium
                                                                      .fontStyle,
                                                            ),
                                                    hintText:
                                                        FFLocalizations.of(
                                                                context)
                                                            .getText(
                                                      '601bzdk7' /* Search Maps */,
                                                    ),
                                                    hintStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .labelLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .roboto(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontStyle,
                                                          ),
                                                          color:
                                                              Color(0xFF6C6C6C),
                                                          fontSize: 17.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontStyle,
                                                        ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Color(0x00000000),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10.0),
                                                      ),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            Color(0x00000000),
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10.0),
                                                      ),
                                                    ),
                                                    errorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10.0),
                                                      ),
                                                    ),
                                                    focusedErrorBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        width: 1.0,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                10.0),
                                                        bottomLeft:
                                                            Radius.circular(
                                                                10.0),
                                                      ),
                                                    ),
                                                    filled: true,
                                                    fillColor: FlutterFlowTheme
                                                            .of(context)
                                                        .secondaryBackground,
                                                    contentPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(6.0, 0.0,
                                                                0.0, 0.0),
                                                    prefixIcon: Icon(
                                                      FFIcons.kicnSearch,
                                                      color: Color(0xFF6C6C6C),
                                                      size: 20.0,
                                                    ),
                                                    suffixIcon:
                                                        _model.textController!
                                                                .text.isNotEmpty
                                                            ? InkWell(
                                                                onTap:
                                                                    () async {
                                                                  _model
                                                                      .textController
                                                                      ?.clear();
                                                                  if (_model.textController
                                                                              .text !=
                                                                          null &&
                                                                      _model.textController
                                                                              .text !=
                                                                          '') {
                                                                    _model.getFilteredParkingsOut =
                                                                        await GetFilteredParkingsCall
                                                                            .call(
                                                                      searchQuery: functions.textToLower(_model
                                                                          .textController
                                                                          .text),
                                                                      isActive:
                                                                          FFAppState()
                                                                              .isFilterApplied,
                                                                      zoom:
                                                                          20.0,
                                                                      radius: FFAppState()
                                                                              .isFilterShowNearest
                                                                          ? functions
                                                                              .getMetersFromIndex(FFAppState().filterRadius)
                                                                          : 0.0,
                                                                      lat: ((_model.latMin!) +
                                                                              (_model.latMax!)) /
                                                                          2,
                                                                      lng: ((_model.lngMin!) +
                                                                              (_model.lngMax!)) /
                                                                          2,
                                                                      minLat: _model
                                                                          .latMin,
                                                                      maxLat: _model
                                                                          .latMax,
                                                                      minLng: _model
                                                                          .lngMin,
                                                                      maxLng: _model
                                                                          .lngMax,
                                                                      minCap: FFAppState()
                                                                          .filterCapacityFrom,
                                                                      maxCap: FFAppState()
                                                                          .filterCapacityTo,
                                                                      gas: FFAppState()
                                                                          .isFilterHasGas,
                                                                      shower: FFAppState()
                                                                          .isFilterHasShower,
                                                                      laundry:
                                                                          FFAppState()
                                                                              .isFilterHasLaundry,
                                                                      hotel: FFAppState()
                                                                          .isFilterHasHotel,
                                                                      shop: FFAppState()
                                                                          .isFilterHasShop,
                                                                      recreation:
                                                                          FFAppState()
                                                                              .isFilterHasRecreation,
                                                                    );

                                                                    _model
                                                                        .searchResults = (_model.getFilteredParkingsOut?.jsonBody ??
                                                                            '')
                                                                        .toList()
                                                                        .cast<
                                                                            dynamic>();
                                                                    _model.isSearching =
                                                                        true;
                                                                    safeSetState(
                                                                        () {});
                                                                  } else {
                                                                    _model.isSearching =
                                                                        false;
                                                                    _model.searchResults =
                                                                        [];
                                                                    safeSetState(
                                                                        () {});
                                                                  }

                                                                  safeSetState(
                                                                      () {});
                                                                  safeSetState(
                                                                      () {});
                                                                },
                                                                child: Icon(
                                                                  Icons.clear,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .searchMapsHinit,
                                                                  size: 22,
                                                                ),
                                                              )
                                                            : null,
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyLarge
                                                      .override(
                                                        font:
                                                            GoogleFonts.roboto(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                        fontSize: 17.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                  cursorColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  enableInteractiveSelection:
                                                      true,
                                                  validator: _model
                                                      .textControllerValidator
                                                      .asValidator(context),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 10.0, 0.0),
                                            child: InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                _model.isSearching = false;
                                                safeSetState(() {});
                                                safeSetState(() {
                                                  _model.textController
                                                      ?.clear();
                                                });
                                                await showModalBottomSheet(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  enableDrag: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return GestureDetector(
                                                      onTap: () {
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                      },
                                                      child: Padding(
                                                        padding: MediaQuery
                                                            .viewInsetsOf(
                                                                context),
                                                        child: FilterWidget(),
                                                      ),
                                                    );
                                                  },
                                                ).then((value) => safeSetState(
                                                    () => _model.filterOut =
                                                        value));

                                                if (_model.filterOut!) {
                                                  _model.apiResultund =
                                                      await GetFilteredParkingsCall
                                                          .call(
                                                    minLat: _model.latMin,
                                                    maxLat: _model.latMax,
                                                    minLng: _model.lngMin,
                                                    maxLng: _model.lngMax,
                                                    radius: FFAppState()
                                                            .isFilterShowNearest
                                                        ? functions
                                                            .getMetersFromIndex(
                                                                FFAppState()
                                                                    .filterRadius)
                                                        : 0.0,
                                                    minCap: FFAppState()
                                                        .filterCapacityFrom,
                                                    maxCap: FFAppState()
                                                        .filterCapacityTo,
                                                    gas: FFAppState()
                                                        .isFilterHasGas,
                                                    shower: FFAppState()
                                                        .isFilterHasShower,
                                                    laundry: FFAppState()
                                                        .isFilterHasLaundry,
                                                    hotel: FFAppState()
                                                        .isFilterHasHotel,
                                                    shop: FFAppState()
                                                        .isFilterHasShop,
                                                    recreation: FFAppState()
                                                        .isFilterHasRecreation,
                                                    isActive: FFAppState()
                                                        .isFilterApplied,
                                                    zoom: _model.currentZoom,
                                                    lat: ((_model.latMin!) +
                                                            (_model.latMax!)) /
                                                        2,
                                                    lng: ((_model.lngMin!) +
                                                            (_model.lngMax!)) /
                                                        2,
                                                  );

                                                  if ((_model.apiResultund
                                                          ?.succeeded ??
                                                      true)) {
                                                    _model.parkingsOnMap =
                                                        (_model.apiResultund
                                                                ?.jsonBody ??
                                                            '');
                                                    safeSetState(() {});
                                                  }
                                                }

                                                safeSetState(() {});
                                              },
                                              child: Container(
                                                width: 40.0,
                                                height: 40.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(10.0),
                                                    bottomRight:
                                                        Radius.circular(10.0),
                                                  ),
                                                ),
                                                child: Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          0.0, 0.0),
                                                  child: Icon(
                                                    FFIcons.ksetting4,
                                                    color: FFAppState()
                                                            .isFilterApplied
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .primary
                                                        : Color(0xFF8E8E93),
                                                    size: 20.0,
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
                                              context.pushNamed(
                                                  ProfileWidget.routeName);
                                            },
                                            child: Container(
                                              width: 36.0,
                                              height: 36.0,
                                              decoration: BoxDecoration(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryBackground,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(0.0),
                                                child: SvgPicture.asset(
                                                  'assets/images/menu.svg',
                                                  width: 24.0,
                                                  height: 24.0,
                                                  fit: BoxFit.none,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    custom_widgets.BottomSpacer(
                                      width: double.infinity,
                                      height: 10.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
