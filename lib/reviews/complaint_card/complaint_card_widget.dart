import '/features/reports/data/reports_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'complaint_card_model.dart';
export 'complaint_card_model.dart';

class ComplaintCardWidget extends StatefulWidget {
  const ComplaintCardWidget({
    super.key,
    required this.complaintRow,
  });

  final UserReport? complaintRow;

  @override
  State<ComplaintCardWidget> createState() => _ComplaintCardWidgetState();
}

class _ComplaintCardWidgetState extends State<ComplaintCardWidget> {
  late ComplaintCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ComplaintCardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(72.0, 0.0, 0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      valueOrDefault<String>(
                        widget!.complaintRow?.parkingAddress,
                        'No address',
                      ),
                      maxLines: 1,
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    valueOrDefault<String>(
                      dateTimeFormat(
                        "dd.MM.y",
                        widget!.complaintRow?.reportDate,
                        locale: FFLocalizations.of(context).languageCode,
                      ),
                      '01.01.2026',
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.roboto(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                  if (widget!.complaintRow?.reportType != 'Report3')
                    Text(
                      () {
                        if (widget!.complaintRow?.reportType == 'Report1') {
                          return FFLocalizations.of(context).getVariableText(
                            enText: 'Parking does not exist',
                            ruText: 'Парковка не существует',
                          );
                        } else if (widget!.complaintRow?.reportType ==
                            'Report2') {
                          return FFLocalizations.of(context).getVariableText(
                            enText: 'A dangerous place',
                            ruText: 'Опасное место',
                          );
                        } else {
                          return '';
                        }
                      }(),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  if (widget!.complaintRow?.reportComment != null &&
                      widget!.complaintRow?.reportComment != '')
                    Flexible(
                      child: Text(
                        valueOrDefault<String>(
                          widget!.complaintRow?.reportComment,
                          '-',
                        ),
                        maxLines: _model.isExpanded ? 100 : 4,
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.roboto(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if ((String text) {
                    return text.length > 160 ||
                        '\n'.allMatches(text).length >= 4;
                  }(widget!.complaintRow!.reportComment!))
                    Builder(
                      builder: (context) {
                        if (!_model.isExpanded) {
                          return InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              _model.isExpanded = true;
                              safeSetState(() {});
                            },
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'yiywuf5r' /* Read more */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                          );
                        } else {
                          return InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              _model.isExpanded = false;
                              safeSetState(() {});
                            },
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'rfovf3hg' /* Show less */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                          );
                        }
                      },
                    ),
                ].divide(SizedBox(height: 6.0)),
              ),
            ),
            Builder(
              builder: (context) {
                if (widget!.complaintRow?.parkingPhotos != null) {
                  return InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      context.pushNamed(
                        PhotoDetailedWidget.routeName,
                        queryParameters: {
                          'photoPath': serializeParam(
                            getJsonField(
                              widget!.complaintRow?.parkingPhotos,
                              r'''$[0]''',
                            ).toString(),
                            ParamType.String,
                          ),
                          'index': serializeParam(
                            0,
                            ParamType.int,
                          ),
                          'address': serializeParam(
                            widget!.complaintRow?.parkingAddress,
                            ParamType.String,
                          ),
                          'photoCount': serializeParam(
                            widget!.complaintRow?.photosCount,
                            ParamType.int,
                          ),
                          'photoRef': serializeParam(
                            getJsonField(
                              widget!.complaintRow?.parkingPhotos,
                              r'''$[0]''',
                            ).toString(),
                            ParamType.String,
                          ),
                          'data': serializeParam(
                            widget!.complaintRow?.reportDate?.toString(),
                            ParamType.String,
                          ),
                        }.withoutNulls,
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99.0),
                      child: Image.network(
                        getJsonField(
                          widget!.complaintRow!.parkingPhotos!,
                          r'''$[0]''',
                        ).toString(),
                        width: 40.0,
                        height: 40.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                } else {
                  return Icon(
                    Icons.no_photography,
                    color: FlutterFlowTheme.of(context).checkBoxes,
                    size: 40.0,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
