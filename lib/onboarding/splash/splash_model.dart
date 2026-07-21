import '/auth/base_auth_user_provider.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'splash_widget.dart' show SplashWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SplashModel extends FlutterFlowModel<SplashWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - getDeviceId] action in Splash widget.
  String? currentId;
  // Stores action output result for [Custom Action - waitForReferralCode] action in Splash widget.
  String? waitedRefCode;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
