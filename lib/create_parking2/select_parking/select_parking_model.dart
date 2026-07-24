import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'select_parking_widget.dart' show SelectParkingWidget;
import 'package:flutter/material.dart';

class SelectParkingModel extends FlutterFlowModel<SelectParkingWidget> {
  ///  Local state fields for this page.

  bool isMapLocked = true;

  List<dynamic>? parkingsOnMap;

  int? requests;

  List<dynamic> searchResults = [];
  void addToSearchResults(dynamic item) => searchResults.add(item);
  void removeFromSearchResults(dynamic item) => searchResults.remove(item);
  void removeAtIndexFromSearchResults(int index) =>
      searchResults.removeAt(index);
  void insertAtIndexInSearchResults(int index, dynamic item) =>
      searchResults.insert(index, item);
  void updateSearchResultsAtIndex(int index, Function(dynamic) updateFn) =>
      searchResults[index] = updateFn(searchResults[index]);

  LatLng? searchCoord;

  bool isSearching = false;

  double? latMin;

  double? latMax;

  double? lngMin;

  double? lngMax;

  double? currentZoom;

  bool isHinitShow = true;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (GetAddressFromCoords)] action in CustomGoogleMap widget.
  ApiCallResponse? getAddressFromCoordsRes;
  // Stores action output result for [Alert Dialog - Custom Dialog] action in CustomGoogleMap widget.
  bool? closeCreateParkingDialogOut;
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
