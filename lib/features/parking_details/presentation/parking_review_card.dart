import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../../../parkings_details/photo_detailed_reviews/photo_detailed_reviews_widget.dart';
import '../domain/parking_details.dart';

class ParkingReviewCard extends StatefulWidget {
  const ParkingReviewCard({
    super.key,
    required this.review,
  });

  final ParkingReview review;

  @override
  State<ParkingReviewCard> createState() => _ParkingReviewCardState();
}

class _ParkingReviewCardState extends State<ParkingReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final comment = widget.review.comment ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _authorName(context),
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
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    0.0,
                    0.0,
                    16.0,
                    0.0,
                  ),
                  child: _avatar(context),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    0.0,
                    0.0,
                    6.0,
                    0.0,
                  ),
                  child: RatingBarIndicator(
                    itemBuilder: (context, index) => Icon(
                      Icons.star_rounded,
                      color: FlutterFlowTheme.of(context).tertiary,
                    ),
                    direction: Axis.horizontal,
                    rating: widget.review.averageScore ?? 3.0,
                    unratedColor: Colors.transparent,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.fromLTRB(0.0, 0.0, 4.0, 0.0),
                    itemSize: 12.0,
                  ),
                ),
                Text(
                  valueOrDefault<String>(
                    dateTimeFormat(
                      'dd.MM.y',
                      widget.review.createdAt,
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
            if (comment.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    66.0,
                    0.0,
                    0.0,
                    0.0,
                  ),
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
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (_isExpandable(comment))
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  66.0,
                  0.0,
                  0.0,
                  0.0,
                ),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Text(
                    _isExpanded
                        ? FFLocalizations.of(context).getText(
                            'px2143v5' /* Show less */,
                          )
                        : FFLocalizations.of(context).getText(
                            '21sa87uf' /* Read more */,
                          ),
                    style: FlutterFlowTheme.of(context).labelMedium.override(
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
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  66.0,
                  0.0,
                  0.0,
                  0.0,
                ),
                child: _photos(context),
              ),
            ),
          ].divide(const SizedBox(height: 6.0)),
        ),
      ),
    );
  }

  String _authorName(BuildContext context) {
    if ((widget.review.userId ?? '').isEmpty) {
      return FFLocalizations.of(context).getVariableText(
        enText: 'Deleted User',
        ruText: 'Удалённый пользователь',
      );
    }

    return valueOrDefault<String>(widget.review.authorName, 'User');
  }

  Widget _avatar(BuildContext context) {
    final avatarUrl = widget.review.authorAvatar;
    if ((widget.review.userId ?? '').isNotEmpty &&
        avatarUrl != null &&
        avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(99.0),
        child: Image.network(
          avatarUrl,
          width: 40.0,
          height: 40.0,
          fit: BoxFit.cover,
        ),
      );
    }

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

  Widget _photos(BuildContext context) {
    final photos = widget.review.reviewPhotos ?? const <String>[];
    if (photos.isEmpty) {
      return Container(
        width: 1.0,
        height: 1.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
        ),
      );
    }

    return SizedBox(
      height: 64.0,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4.0),
        itemBuilder: (context, index) {
          final photoUrl = photos[index];
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
                    photoUrl,
                    ParamType.String,
                  ),
                }.withoutNulls,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                photoUrl,
                width: 64.0,
                height: 64.0,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isExpandable(String text) {
    return text.length > 160 || '\n'.allMatches(text).length >= 4;
  }
}
