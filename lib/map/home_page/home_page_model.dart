import '/flutter_flow/flutter_flow_util.dart';
import '/features/map/presentation/map_marker_item.dart';
import '/features/map/presentation/map_search_result_item.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  bool isMapLocked = true;

  List<MapMarkerItem> parkingsOnMap = const [];

  int? requests;

  List<MapSearchResultItem> searchResults = [];
  void addToSearchResults(MapSearchResultItem item) => searchResults.add(item);
  void removeFromSearchResults(MapSearchResultItem item) =>
      searchResults.remove(item);
  void removeAtIndexFromSearchResults(int index) =>
      searchResults.removeAt(index);
  void insertAtIndexInSearchResults(int index, MapSearchResultItem item) =>
      searchResults.insert(index, item);
  void updateSearchResultsAtIndex(int index,
          MapSearchResultItem Function(MapSearchResultItem) updateFn) =>
      searchResults[index] = updateFn(searchResults[index]);

  LatLng? searchCoord;

  int mapCenterRequestId = 0;

  bool isRefreshingUserLocation = false;

  bool isSearching = false;

  double? latMin;

  double? latMax;

  double? lngMin;

  double? lngMax;

  double? currentZoom;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - fetchPremiumExpirationDate] action in HomePage widget.
  DateTime? fetchPremiumExpirationDateOut;
  // Stores action output result for [Alert Dialog - Custom Dialog] action in CustomGoogleMap widget.
  bool? closeCreateParkingDialogOut;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Bottom Sheet - Filter] action in Container widget.
  bool? filterOut;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
