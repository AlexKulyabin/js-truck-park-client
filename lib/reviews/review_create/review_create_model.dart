import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/features/review_submission/data/review_submission_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'review_create_widget.dart' show ReviewCreateWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewCreateModel extends FlutterFlowModel<ReviewCreateWidget> {
  ///  Local state fields for this component.

  MainImpression? mainIimpression;

  List<FFUploadedFile> photos = [];
  void addToPhotos(FFUploadedFile item) => photos.add(item);
  void removeFromPhotos(FFUploadedFile item) => photos.remove(item);
  void removeAtIndexFromPhotos(int index) => photos.removeAt(index);
  void insertAtIndexInPhotos(int index, FFUploadedFile item) =>
      photos.insert(index, item);
  void updatePhotosAtIndex(int index, Function(FFUploadedFile) updateFn) =>
      photos[index] = updateFn(photos[index]);

  ConvenienceOfTruckArrival? convenienceOfTruckArrival;

  Infrastructure? infrastructure;

  SecurityLevel? securityLevel;

  ComfortForRelaxation? comfortForRelaxation;

  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  bool isDataUploading_uploadDataRew2 = false;
  FFUploadedFile uploadedLocalFile_uploadDataRew2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  final reviewSubmissionService = ReviewSubmissionService();
  // Stores action output result for [ReviewSubmissionService.submit] action in Button widget.
  ReviewSubmissionResult? createReviewOut;
  bool isDataUploading_uploadDataYj0 = false;
  FFUploadedFile uploadedLocalFile_uploadDataYj0 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataYj0 = '';

  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ParkingPhotosRow? createParkingPhotosOut;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
