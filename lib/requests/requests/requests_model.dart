import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/requests/request_card/request_card_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'requests_widget.dart' show RequestsWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RequestsModel extends FlutterFlowModel<RequestsWidget> {
  ///  Local state fields for this page.

  bool isModerationTabOn = true;

  bool isAcceptedTabOn = false;

  bool isRejectedTabOn = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
