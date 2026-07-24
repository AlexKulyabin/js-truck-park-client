import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/features/reviews/data/reviews_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/reviews/report_create/report_create_widget.dart';
import '/reviews/review_card_parking_details/review_card_parking_details_widget.dart';
import '/reviews/review_create/review_create_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'reviews_tab_widget.dart' show ReviewsTabWidget;
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class ReviewsTabModel extends FlutterFlowModel<ReviewsTabWidget> {
  ///  State fields for stateful widgets in this component.

  final reviewsService = ReviewsService();

  // State field(s) for RatingBar widget.
  double? ratingBarValue1;
  // State field(s) for RatingBar widget.
  double? ratingBarValue2;
  // State field(s) for RatingBar widget.
  double? ratingBarValue3;
  // State field(s) for RatingBar widget.
  double? ratingBarValue4;
  // State field(s) for RatingBar widget.
  double? ratingBarValue5;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
