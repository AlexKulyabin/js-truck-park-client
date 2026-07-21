import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/reviews/complaint_card/complaint_card_widget.dart';
import '/reviews/review_card_profile/review_card_profile_widget.dart';
import 'dart:ui';
import 'reviews_and_complaints_widget.dart' show ReviewsAndComplaintsWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewsAndComplaintsModel
    extends FlutterFlowModel<ReviewsAndComplaintsWidget> {
  ///  Local state fields for this page.

  bool isReviewsTabOn = true;

  bool isComplaintsTabOn = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
