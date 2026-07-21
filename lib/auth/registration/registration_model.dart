import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'registration_widget.dart' show RegistrationWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegistrationModel extends FlutterFlowModel<RegistrationWidget> {
  ///  Local state fields for this page.

  FFUploadedFile? photo;

  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadData22 = false;
  FFUploadedFile uploadedLocalFile_uploadData22 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  bool isDataUploading_uploadData2g = false;
  FFUploadedFile uploadedLocalFile_uploadData2g =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // State field(s) for Name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;
  bool isDataUploading_uploadData9f = false;
  FFUploadedFile uploadedLocalFile_uploadData9f =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadData9f = '';

  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UsersRow>? updateUserOut1;
  // Stores action output result for [Backend Call - Update Row(s)] action in Button widget.
  List<UsersRow>? updateUserOut2;
  // Stores action output result for [Backend Call - API (ProcessReferral)] action in Button widget.
  ApiCallResponse? apiResult8fn;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();
  }
}
