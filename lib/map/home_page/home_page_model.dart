import '/backend/api_requests/api_calls.dart';
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
import 'home_page_widget.dart' show HomePageWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  bool isMapLocked = true;

  dynamic parkingsOnMap;

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

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - fetchPremiumExpirationDate] action in HomePage widget.
  DateTime? fetchPremiumExpirationDateOut;
  // Stores action output result for [Backend Call - API (GetAddressFromCoords)] action in CustomGoogleMap widget.
  ApiCallResponse? getAddressFromCoordsRes;
  // Stores action output result for [Alert Dialog - Custom Dialog] action in CustomGoogleMap widget.
  bool? closeCreateParkingDialogOut;
  // Stores action output result for [Backend Call - API (GetFilteredParkings)] action in CustomGoogleMap widget.
  ApiCallResponse? getFilteredParkings;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (GetFilteredParkings)] action in TextField widget.
  ApiCallResponse? getFilteredParkingsOut;
  // Stores action output result for [Bottom Sheet - Filter] action in Container widget.
  bool? filterOut;
  // Stores action output result for [Backend Call - API (GetFilteredParkings)] action in Container widget.
  ApiCallResponse? apiResultund;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
