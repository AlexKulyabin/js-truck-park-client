import '/flutter_flow/flutter_flow_util.dart';
import 'create_parking_widget.dart' show CreateParkingWidget;
import 'package:flutter/material.dart';

class CreateParkingModel extends FlutterFlowModel<CreateParkingWidget> {
  ///  Local state fields for this page.

  List<FFUploadedFile> photos = [];
  void addToPhotos(FFUploadedFile item) => photos.add(item);
  void removeFromPhotos(FFUploadedFile item) => photos.remove(item);
  void removeAtIndexFromPhotos(int index) => photos.removeAt(index);
  void insertAtIndexInPhotos(int index, FFUploadedFile item) =>
      photos.insert(index, item);
  void updatePhotosAtIndex(int index, Function(FFUploadedFile) updateFn) =>
      photos[index] = updateFn(photos[index]);

  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataRew = false;
  FFUploadedFile uploadedLocalFile_uploadDataRew =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // State field(s) for Capasity widget.
  FocusNode? capasityFocusNode;
  TextEditingController? capasityTextController;
  String? Function(BuildContext, String?)? capasityTextControllerValidator;
  // State field(s) for GasStation widget.
  bool? gasStationValue;
  // State field(s) for Shower widget.
  bool? showerValue;
  // State field(s) for Laundry widget.
  bool? laundryValue;
  // State field(s) for Hotel widget.
  bool? hotelValue;
  // State field(s) for Shop widget.
  bool? shopValue;
  // State field(s) for RecreationArea widget.
  bool? recreationAreaValue;
  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    capasityFocusNode?.dispose();
    capasityTextController?.dispose();
  }
}
