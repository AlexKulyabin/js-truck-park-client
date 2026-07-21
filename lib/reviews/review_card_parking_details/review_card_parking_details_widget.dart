import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'review_card_parking_details_model.dart';
export 'review_card_parking_details_model.dart';

class ReviewCardParkingDetailsWidget extends StatefulWidget {
  const ReviewCardParkingDetailsWidget({
    super.key,
    required this.reviewRow,
  });

  final ViewReviewsWithUsersRow? reviewRow;

  @override
  State<ReviewCardParkingDetailsWidget> createState() =>
      _ReviewCardParkingDetailsWidgetState();
}

class _ReviewCardParkingDetailsWidgetState
    extends State<ReviewCardParkingDetailsWidget> {
  late ReviewCardParkingDetailsModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewCardParkingDetailsModel());

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valueOrDefault<String>(
                widget!.reviewRow?.userId != null &&
                        widget!.reviewRow?.userId != ''
                    ? widget!.reviewRow?.authorName
                    : FFLocalizations.of(context).getVariableText(
                        enText: 'Deleted User',
                        ruText: 'Удалённый пользователь',
                      ),
                'User',
              ),
              style: FlutterFlowTheme.of(context).bodyLarge.override(
                    font: GoogleFonts.roboto(
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                  ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                  child: Builder(
                    builder: (context) {
                      if ((widget!.reviewRow?.userId != null &&
                              widget!.reviewRow?.userId != '') &&
                          (widget!.reviewRow?.authorAvatar != null &&
                              widget!.reviewRow?.authorAvatar != '')) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(99.0),
                          child: Image.network(
                            widget!.reviewRow!.authorAvatar!,
                            width: 40.0,
                            height: 40.0,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(99.0),
                          child: SvgPicture.asset(
                            'assets/images/profile.svg',
                            width: 40.0,
                            height: 40.0,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 6.0, 0.0),
                  child: RatingBarIndicator(
                    itemBuilder: (context, index) => Icon(
                      Icons.star_rounded,
                      color: FlutterFlowTheme.of(context).tertiary,
                    ),
                    direction: Axis.horizontal,
                    rating: valueOrDefault<double>(
                      widget!.reviewRow?.averageScore,
                      3.0,
                    ),
                    unratedColor: Colors.transparent,
                    itemCount: 5,
                    itemPadding: EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                    itemSize: 12.0,
                  ),
                ),
                Text(
                  valueOrDefault<String>(
                    dateTimeFormat(
                      "dd.MM.y",
                      widget!.reviewRow?.createdAt,
                      locale: FFLocalizations.of(context).languageCode,
                    ),
                    '01.01.2026',
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.roboto(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                ),
              ],
            ),
            if (widget!.reviewRow?.comment != null &&
                widget!.reviewRow?.comment != '')
              Flexible(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(66.0, 0.0, 0.0, 0.0),
                  child: Text(
                    valueOrDefault<String>(
                      widget!.reviewRow?.comment,
                      '.',
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
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if ((String text) {
              return text.length > 160 || '\n'.allMatches(text).length >= 4;
            }(widget!.reviewRow!.comment!))
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(66.0, 0.0, 0.0, 0.0),
                child: Builder(
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
                            '21sa87uf' /* Read more */,
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
                            'px2143v5' /* Show less */,
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
                      );
                    }
                  },
                ),
              ),
            Flexible(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(66.0, 0.0, 0.0, 0.0),
                child: Builder(
                  builder: (context) {
                    if (widget!.reviewRow?.reviewPhotos != null) {
                      return Container(
                        height: 64.0,
                        decoration: BoxDecoration(),
                        child: Builder(
                          builder: (context) {
                            final photos =
                                widget!.reviewRow?.reviewPhotos?.toList() ?? [];

                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: photos.length,
                              separatorBuilder: (_, __) => SizedBox(width: 4.0),
                              itemBuilder: (context, photosIndex) {
                                final photosItem = photos[photosIndex];
                                return InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    context.pushNamed(
                                      PhotoDetailedReviewsWidget.routeName,
                                      queryParameters: {
                                        'photoPath': serializeParam(
                                          photosItem.toString(),
                                          ParamType.String,
                                        ),
                                      }.withoutNulls,
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Image.network(
                                      photosItem.toString(),
                                      width: 64.0,
                                      height: 64.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      return Container(
                        width: 1.0,
                        height: 1.0,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ].divide(SizedBox(height: 6.0)),
        ),
      ),
    );
  }
}
