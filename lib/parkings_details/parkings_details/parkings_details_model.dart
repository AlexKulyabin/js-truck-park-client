import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/parkings_details/info_tab/info_tab_widget.dart';
import '/parkings_details/photos_tab/photos_tab_widget.dart';
import '/parkings_details/reviews_tab/reviews_tab_widget.dart';
import 'parkings_details_widget.dart' show ParkingsDetailsWidget;
import 'package:flutter/material.dart';

class ParkingsDetailsModel extends FlutterFlowModel<ParkingsDetailsWidget> {
  ///  Local state fields for this component.

  TabsToggle? activeTab = TabsToggle.info;

  ///  State fields for stateful widgets in this component.

  // State field(s) for PageView widget.
  PageController? pageViewController;

  int get pageViewCurrentIndex => pageViewController != null &&
          pageViewController!.hasClients &&
          pageViewController!.page != null
      ? pageViewController!.page!.round()
      : 0;
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
