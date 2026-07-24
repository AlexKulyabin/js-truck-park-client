import '/create_parking2/create_parking_dialog2/create_parking_dialog2_widget.dart';
import '/features/geocoding/application/reverse_geocoding_service.dart';
import '/features/geocoding/data/google_reverse_geocoding_repository.dart';
import '/features/geocoding/domain/reverse_geocoding_repository.dart';
import '/features/map/application/parking_map_controller.dart';
import '/features/map/data/supabase_parking_map_repository.dart';
import '/features/map/domain/map_bounds.dart';
import '/features/map/domain/map_parking_query.dart';
import '/features/map/domain/parking_map_repository.dart';
import '/features/map/presentation/map_read_adapter.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/parkings_details/parkings_details/parkings_details_widget.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'select_parking_model.dart';
export 'select_parking_model.dart';

class SelectParkingWidget extends StatefulWidget {
  const SelectParkingWidget({
    super.key,
    this.parkingMapRepository,
    this.reverseGeocodingRepository,
  });

  final ParkingMapRepository? parkingMapRepository;
  final ReverseGeocodingRepository? reverseGeocodingRepository;

  static String routeName = 'SelectParking';
  static String routePath = '/selectParking';

  @override
  State<SelectParkingWidget> createState() => _SelectParkingWidgetState();
}

class _SelectParkingWidgetState extends State<SelectParkingWidget> {
  late SelectParkingModel _model;
  late final ParkingMapController _parkingMapController;
  late final ReverseGeocodingService _reverseGeocodingService;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SelectParkingModel());
    _parkingMapController = ParkingMapController(
      repository: widget.parkingMapRepository ?? SupabaseParkingMapRepository(),
    );
    _reverseGeocodingService = ReverseGeocodingService(
      repository: widget.reverseGeocodingRepository ??
          GoogleReverseGeocodingRepository(),
    );

    getCurrentUserLocation(defaultLocation: LatLng(0.0, 0.0), cached: true)
        .then((loc) => safeSetState(() => currentUserLocationValue = loc));
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _parkingMapController.dispose();
    _model.dispose();

    super.dispose();
  }

  MapFilterSnapshot _currentFilterSnapshot() => MapFilterSnapshot(
        radiusMeters: FFAppState().isFilterShowNearest
            ? functions.getMetersFromIndex(FFAppState().filterRadius)
            : 0.0,
        minCapacity: FFAppState().filterCapacityFrom,
        maxCapacity: FFAppState().filterCapacityTo,
        needGas: FFAppState().isFilterHasGas,
        needShower: FFAppState().isFilterHasShower,
        needLaundry: FFAppState().isFilterHasLaundry,
        needHotel: FFAppState().isFilterHasHotel,
        needShop: FFAppState().isFilterHasShop,
        needRecreation: FFAppState().isFilterHasRecreation,
        isActive: FFAppState().isFilterApplied,
      );

  MapParkingQuery _buildMapQuery({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    required double zoom,
  }) =>
      buildMapParkingQuery(
        bounds: MapBounds(
          minLatitude: minLat,
          minLongitude: minLng,
          maxLatitude: maxLat,
          maxLongitude: maxLng,
        ),
        zoom: zoom,
        filter: _currentFilterSnapshot(),
      );

  Future<void> _loadMapPoints(MapParkingQuery query) async {
    await _parkingMapController.load(query);
    if (!mounted) {
      return;
    }
    final state = _parkingMapController.state;
    if (!identical(state.query, query) ||
        state.phase != ParkingMapLoadPhase.loaded) {
      return;
    }
    safeSetState(() {
      _model.parkingsOnMap = toMapMarkerItems(state.points);
    });
  }

  Future<void> _updateTemporaryAddress({
    required double latitude,
    required double longitude,
  }) async {
    FFAppState().tempAddress = await _reverseGeocodingService.resolveAddress(
      latitude: latitude,
      longitude: longitude,
    );
    if (mounted) {
      safeSetState(() {});
    }
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
        body: SafeArea(
          top: true,
          child: Stack(
            alignment: AlignmentDirectional(0.0, 1.0),
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Builder(
                    builder: (context) => Container(
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      child: custom_widgets.CustomGoogleMap(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        height: MediaQuery.sizeOf(context).height * 1.0,
                        initialLat: functions.getLat(currentUserLocationValue),
                        initialLng: functions.getLng(currentUserLocationValue),
                        initialZoom: 13.0,
                        allowGestures: true,
                        markerIconPath:
                            'https://jckksrcdmhtafwbimzov.supabase.co/storage/v1/object/public/assets/icnLocation.png',
                        markerSize: 30,
                        markers: _model.parkingsOnMap,
                        centerToMoveTo: _model.searchCoord,
                        isDarkMode: false,
                        onMarkerTap: (markerId) async {
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
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                child: Padding(
                                  padding: MediaQuery.viewInsetsOf(context),
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
                          await _loadMapPoints(
                            _buildMapQuery(
                              minLat: minLat,
                              minLng: minLng,
                              maxLat: maxLat,
                              maxLng: maxLng,
                              zoom: zoom,
                            ),
                          );
                        },
                        onLongPress: (longPressedPoint) async {
                          FFAppState().tempLat =
                              functions.getLat(longPressedPoint);
                          FFAppState().tempLng =
                              functions.getLng(longPressedPoint);
                          safeSetState(() {});
                          await _updateTemporaryAddress(
                            latitude: FFAppState().tempLat,
                            longitude: FFAppState().tempLng,
                          );
                          if (!mounted) {
                            return;
                          }
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
                                    FocusScope.of(dialogContext).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                  child: CreateParkingDialog2Widget(),
                                ),
                              );
                            },
                          ).then((value) => safeSetState(() =>
                              _model.closeCreateParkingDialogOut = value));

                          safeSetState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_model.isHinitShow)
                Align(
                  alignment: AlignmentDirectional(0.0, -1.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 30.0, 24.0, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 16.0, 16.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.pin_drop,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 24.0,
                            ),
                            Flexible(
                              child: Text(
                                FFLocalizations.of(context).getText(
                                  'nu5ik2xh' /* Press and hold on the map to s... */,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .override(
                                      font: GoogleFonts.roboto(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                _model.isHinitShow = false;
                                safeSetState(() {});
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                size: 24.0,
                              ),
                            ),
                          ].divide(SizedBox(width: 16.0)),
                        ),
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
}
