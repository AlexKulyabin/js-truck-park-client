import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/parkings_details/info_tab/info_tab_widget.dart';
import '/parkings_details/photos_tab/photos_tab_widget.dart';
import '/parkings_details/reviews_tab/reviews_tab_widget.dart';
import '/subscription/guest_dialog/guest_dialog_widget.dart';
import '/subscription/subscription_dialog/subscription_dialog_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'
    as smooth_page_indicator;
import 'parkings_details_widget.dart' show ParkingsDetailsWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ParkingsDetailsModel extends FlutterFlowModel<ParkingsDetailsWidget> {
  ///  Local state fields for this component.

  TabsToggle? activeTab = TabsToggle.info;

  bool? isFavorite;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in ParkingsDetails widget.
  List<FavoritesRow>? isFavoriteOut;
  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
  // Stores action output result for [Backend Call - Delete Row(s)] action in FavoriteButton widget.
  List<FavoritesRow>? deletefavoriteOut;
  // Stores action output result for [Backend Call - Insert Row] action in FavoriteButton widget.
  FavoritesRow? addFavoriteOut;
  // Model for InfoTab component.
  late InfoTabModel infoTabModel;
  // Model for ReviewsTab component.
  late ReviewsTabModel reviewsTabModel;
  // Model for PhotosTab component.
  late PhotosTabModel photosTabModel;

  @override
  void initState(BuildContext context) {
    infoTabModel = createModel(context, () => InfoTabModel());
    reviewsTabModel = createModel(context, () => ReviewsTabModel());
    photosTabModel = createModel(context, () => PhotosTabModel());
  }

  @override
  void dispose() {
    infoTabModel.dispose();
    reviewsTabModel.dispose();
    photosTabModel.dispose();
  }
}
