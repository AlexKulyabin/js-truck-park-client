import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/features/profile/data/user_profile_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/profile/invite_friends_dialog/invite_friends_dialog_widget.dart';
import '/profile/log_out_dialog/log_out_dialog_widget.dart';
import '/profile/log_out_dialog_copy/log_out_dialog_copy_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'profile_widget.dart' show ProfileWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileModel extends FlutterFlowModel<ProfileWidget> {
  ///  Local state fields for this page.

  bool tempInvite = false;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in InviteContainer widget.
  List<UserProfile>? currentUserOut;
  // Stores action output result for [Custom Action - createReferralLink] action in InviteContainer widget.
  String? referralLink;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
