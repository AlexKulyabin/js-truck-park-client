import '/features/parking_details/data/parking_details_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'photos_tab_model.dart';
export 'photos_tab_model.dart';

class PhotosTabWidget extends StatefulWidget {
  const PhotosTabWidget({
    super.key,
    required this.parkingRow,
  });

  final ParkingDetails? parkingRow;

  @override
  State<PhotosTabWidget> createState() => _PhotosTabWidgetState();
}

class _PhotosTabWidgetState extends State<PhotosTabWidget> {
  late PhotosTabModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PhotosTabModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (widget!.parkingRow?.allPhotos != null) {
          return Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 60.0),
            child: Builder(
              builder: (context) {
                final photos = widget!.parkingRow?.allPhotos?.toList() ?? [];

                return MasonryGridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  crossAxisSpacing: 2.0,
                  mainAxisSpacing: 2.0,
                  itemCount: photos.length,
                  shrinkWrap: true,
                  itemBuilder: (context, photosIndex) {
                    final photosItem = photos[photosIndex];
                    return AspectRatio(
                      aspectRatio: 1.0,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.pushNamed(
                            PhotoDetailedWidget.routeName,
                            queryParameters: {
                              'photoPath': serializeParam(
                                photosItem.url.toString(),
                                ParamType.String,
                              ),
                              'index': serializeParam(
                                photosIndex,
                                ParamType.int,
                              ),
                              'address': serializeParam(
                                widget!.parkingRow?.address,
                                ParamType.String,
                              ),
                              'photoCount': serializeParam(
                                widget!.parkingRow?.photosCount,
                                ParamType.int,
                              ),
                              'photoRef': serializeParam(
                                photosItem.url.toString(),
                                ParamType.String,
                              ),
                              'data': serializeParam(
                                photosItem.photoDate.toString(),
                                ParamType.String,
                              ),
                            }.withoutNulls,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0.0),
                          child: Image.network(
                            photosItem.url.toString(),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        } else {
          return AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              width: double.infinity,
              height: 100.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondaryBackground,
              ),
              child: Icon(
                Icons.no_photography,
                color: FlutterFlowTheme.of(context).checkBoxes,
                size: 100.0,
              ),
            ),
          );
        }
      },
    );
  }
}
