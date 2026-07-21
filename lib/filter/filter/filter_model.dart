import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'filter_widget.dart' show FilterWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FilterModel extends FlutterFlowModel<FilterWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Slider widget.
  double? sliderValue;
  // State field(s) for CapasityFrom widget.
  FocusNode? capasityFromFocusNode;
  TextEditingController? capasityFromTextController;
  String? Function(BuildContext, String?)? capasityFromTextControllerValidator;
  // State field(s) for CapasityUpTo widget.
  FocusNode? capasityUpToFocusNode;
  TextEditingController? capasityUpToTextController;
  String? Function(BuildContext, String?)? capasityUpToTextControllerValidator;
  // State field(s) for GasCheckbox widget.
  bool? gasCheckboxValue;
  // State field(s) for SowerCheckbox widget.
  bool? sowerCheckboxValue;
  // State field(s) for LaundryCheckbox widget.
  bool? laundryCheckboxValue;
  // State field(s) for HotelCheckbox widget.
  bool? hotelCheckboxValue;
  // State field(s) for ShopCheckbox widget.
  bool? shopCheckboxValue;
  // State field(s) for RecrCheckbox widget.
  bool? recrCheckboxValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    capasityFromFocusNode?.dispose();
    capasityFromTextController?.dispose();

    capasityUpToFocusNode?.dispose();
    capasityUpToTextController?.dispose();
  }
}
