import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../domain/user_review_summary.dart';

class UserReviewCard extends StatefulWidget {
  const UserReviewCard({
    super.key,
    required this.review,
  });

  final UserReviewSummary review;

  @override
  State<UserReviewCard> createState() => _UserReviewCardState();
}

class _UserReviewCardState extends State<UserReviewCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final comment = widget.review.comment;

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
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.review.parkingAddress,
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
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
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
                              rating: widget.review.averageScore,
                              unratedColor: Colors.transparent,
                              itemCount: 5,
                              itemPadding: const EdgeInsets.fromLTRB(
                                0.0,
                                0.0,
                                4.0,
                                0.0,
                              ),
                              itemSize: 12.0,
                            ),
                          ),
                          Text(
                            valueOrDefault<String>(
                              dateTimeFormat(
                                'dd.MM.y',
                                widget.review.createdAt,
                                locale:
                                    FFLocalizations.of(context).languageCode,
                              ),
                              '01.01.2026',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
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
                        ],
                      ),
                    ].divide(const SizedBox(height: 6.0)),
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
                            '5x70xto7' /* Show less */,
                          )
                        : FFLocalizations.of(context).getText(
                            '5i8dq960' /* Read more */,
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

  Widget _avatar(BuildContext context) {
    final avatarUrl = widget.review.authorAvatarUrl;
    if (avatarUrl != null) {
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
    if (widget.review.photoUrls.isEmpty) {
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
        itemCount: widget.review.photoUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4.0),
        itemBuilder: (context, index) {
          final photoUrl = widget.review.photoUrls[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              photoUrl,
              width: 64.0,
              height: 64.0,
              fit: BoxFit.cover,
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
