import '/core/config/app_config.dart';
import '/create_parking/create_parking_dialog/create_parking_dialog_widget.dart';
import '/features/geocoding/application/reverse_geocoding_service.dart';
import '/features/geocoding/data/google_reverse_geocoding_repository.dart';
import '/features/geocoding/domain/reverse_geocoding_repository.dart';
import '/features/map/application/parking_map_controller.dart';
import '/features/map/data/supabase_parking_map_repository.dart';
import '/features/map/domain/map_bounds.dart';
import '/features/map/domain/map_parking_query.dart';
import '/features/map/domain/parking_map_repository.dart';
import '/features/map/presentation/home_map_search_panel.dart';
import '/features/map/presentation/map_read_adapter.dart';
import '/features/map/presentation/map_search_result_item.dart';
import '/filter/filter/filter_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/parkings_details/parkings_details/parkings_details_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'search_panel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({
    super.key,
    this.targetParkingId,
    this.targetLat,
    this.targetLng,
    this.parkingMapRepository,
    this.reverseGeocodingRepository,
  });

  final String? targetParkingId;
  final double? targetLat;
  final double? targetLng;
  final ParkingMapRepository? parkingMapRepository;
  final ReverseGeocodingRepository? reverseGeocodingRepository;

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;
  late final ParkingMapController _parkingMapController;
  late final ParkingMapController _parkingSearchController;
  late final ReverseGeocodingService _reverseGeocodingService;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());
    final parkingMapRepository =
        widget.parkingMapRepository ?? SupabaseParkingMapRepository();
    _parkingMapController = ParkingMapController(
      repository: parkingMapRepository,
    );
    _parkingSearchController = ParkingMapController(
      repository: parkingMapRepository,
    );
    _reverseGeocodingService = ReverseGeocodingService(
      repository: widget.reverseGeocodingRepository ??
          GoogleReverseGeocodingRepository(),
    );

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (AppConfig.current.integrationReadOnly) {
        return;
      }
      if (FFAppState().isGuest == true) {
        return;
      }
      if (widget.targetParkingId != null && widget.targetParkingId != '') {
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
                  parkingId: widget.targetParkingId!,
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
    _parkingMapController.dispose();
    _parkingSearchController.dispose();
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
    String searchQuery = '',
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
        searchQuery: searchQuery,
      );

  MapParkingQuery? _buildCurrentMapQuery({
    double? zoom,
    String searchQuery = '',
  }) {
    final minLat = _model.latMin;
    final minLng = _model.lngMin;
    final maxLat = _model.latMax;
    final maxLng = _model.lngMax;
    final currentZoom = zoom ?? _model.currentZoom;
    if (minLat == null ||
        minLng == null ||
        maxLat == null ||
        maxLng == null ||
        currentZoom == null) {
      return null;
    }
    return _buildMapQuery(
      minLat: minLat,
      minLng: minLng,
      maxLat: maxLat,
      maxLng: maxLng,
      zoom: currentZoom,
      searchQuery: searchQuery,
    );
  }

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

  Future<void> _loadSearchResults(MapParkingQuery query) async {
    await _parkingSearchController.load(query);
    if (!mounted) {
      return;
    }
    final state = _parkingSearchController.state;
    if (!identical(state.query, query) ||
        state.phase != ParkingMapLoadPhase.loaded) {
      return;
    }
    safeSetState(() {
      _model.searchResults = toMapSearchResultItems(state.points);
      _model.isSearching = true;
    });
  }

  void _clearSearchResults() {
    _parkingSearchController.reset();
    safeSetState(() {
      _model.isSearching = false;
      _model.searchResults = [];
    });
  }

  Future<void> _handleSearchQueryChanged(String queryText) async {
    if (queryText.isEmpty) {
      _clearSearchResults();
      return;
    }
    final query = _buildCurrentMapQuery(
      zoom: 20.0,
      searchQuery: functions.textToLower(queryText),
    );
    if (query != null) {
      await _loadSearchResults(query);
    }
  }

  Future<void> _handleSearchResultSelected(
    MapSearchResultItem result,
  ) async {
    _model.searchCoord = LatLng(result.latitude, result.longitude);
    _model.isMapLocked = false;
    _model.textController?.clear();
    _parkingSearchController.reset();
    _model.isSearching = false;
    _model.searchResults = [];
    safeSetState(() {});
    await actions.hideKeyboard();
    if (!mounted) {
      return;
    }
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Padding(
          padding: MediaQuery.viewInsetsOf(context),
          child: ParkingsDetailsWidget(parkingId: result.id),
        ),
      ),
    ).then((_) => safeSetState(() {}));
  }

  Future<void> _handleFilterSelected() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Padding(
          padding: MediaQuery.viewInsetsOf(context),
          child: FilterWidget(),
        ),
      ),
    ).then(
      (value) => safeSetState(() => _model.filterOut = value),
    );
    if (!mounted || _model.filterOut != true) {
      return;
    }
    final query = _buildCurrentMapQuery();
    if (query != null) {
      await _loadMapPoints(query);
    }
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

    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardInset > 0.0;

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
                              initialLat: widget.targetLat != null
                                  ? widget.targetLat!
                                  : functions.getLat(currentUserLocationValue),
                              initialLng: widget.targetLng != null
                                  ? widget.targetLng!
                                  : functions.getLng(currentUserLocationValue),
                              initialZoom: 13.0,
                              allowGestures: true,
                              markerIconPath:
                                  'https://jckksrcdmhtafwbimzov.supabase.co/storage/v1/object/public/assets/icnLocation.png',
                              markerSize: 30,
                              markers: _model.parkingsOnMap,
                              centerToMoveTo: _model.searchCoord,
                              isDarkMode: Theme.of(context).brightness ==
                                  Brightness.dark,
                              clusterSize: 120,
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
                                if (AppConfig.current.integrationReadOnly) {
                                  return;
                                }
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
                if (!isKeyboardVisible)
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
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0)
                                                .resolve(
                                                    Directionality.of(context)),
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

                                context
                                    .pushNamed(CreateParkingWidget.routeName);
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
                HomeMapSearchPanel(
                  maxHeight: searchPanelMaxHeight(
                    screenHeight: mediaQuery.size.height,
                    keyboardInset: keyboardInset,
                  ),
                  textController: _model.textController!,
                  focusNode: _model.textFieldFocusNode!,
                  validator:
                      _model.textControllerValidator.asValidator(context),
                  isSearching: _model.isSearching,
                  results: _model.searchResults,
                  isFilterApplied: FFAppState().isFilterApplied,
                  onQueryChanged: _handleSearchQueryChanged,
                  onClear: _clearSearchResults,
                  onResultSelected: _handleSearchResultSelected,
                  onFilterSelected: _handleFilterSelected,
                  onProfileSelected: () {
                    context.pushNamed(ProfileWidget.routeName);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
