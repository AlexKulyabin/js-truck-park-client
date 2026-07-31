import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../domain/user_complaint_summary.dart';

class UserComplaintCard extends StatefulWidget {
  const UserComplaintCard({
    super.key,
    required this.complaint,
    required this.onPhotoSelected,
  });

  final UserComplaintSummary complaint;
  final ValueChanged<UserComplaintSummary> onPhotoSelected;

  @override
  State<UserComplaintCard> createState() => _UserComplaintCardState();
}

class _UserComplaintCardState extends State<UserComplaintCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final comment = widget.complaint.comment;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                72.0,
                0.0,
                0.0,
                0.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      widget.complaint.parkingAddress,
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
                        'dd.MM.y',
                        widget.complaint.reportDate,
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
                  if (widget.complaint.reportType != 'Report3')
                    Text(
                      _reportTypeText(context),
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
                  if (comment.isNotEmpty)
                    Flexible(
                      child: Text(
                        comment,
                        maxLines: _isExpanded ? 100 : 4,
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
                  if (_isExpandable(comment))
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded
                            ? FFLocalizations.of(context).getText(
                                'rfovf3hg' /* Show less */,
                              )
                            : FFLocalizations.of(context).getText(
                                'yiywuf5r' /* Read more */,
                              ),
                        style:
                            FlutterFlowTheme.of(context).labelMedium.override(
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
                    ),
                ].divide(const SizedBox(height: 6.0)),
              ),
            ),
            _photo(context),
          ],
        ),
      ),
    );
  }

  Widget _photo(BuildContext context) {
    final firstPhotoUrl = widget.complaint.firstParkingPhotoUrl;
    if (firstPhotoUrl == null) {
      return Icon(
        Icons.no_photography,
        color: FlutterFlowTheme.of(context).checkBoxes,
        size: 40.0,
      );
    }

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => widget.onPhotoSelected(widget.complaint),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99.0),
        child: Image.network(
          firstPhotoUrl,
          width: 40.0,
          height: 40.0,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _reportTypeText(BuildContext context) {
    return switch (widget.complaint.reportType) {
      'Report1' => FFLocalizations.of(context).getVariableText(
          enText: 'Parking does not exist',
          ruText: 'Парковка не существует',
        ),
      'Report2' => FFLocalizations.of(context).getVariableText(
          enText: 'A dangerous place',
          ruText: 'Опасное место',
        ),
      _ => '',
    };
  }

  bool _isExpandable(String text) {
    return text.length > 160 || '\n'.allMatches(text).length >= 4;
  }
}
