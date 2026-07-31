import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../domain/parking_request_summary.dart';

class ParkingRequestCard extends StatelessWidget {
  const ParkingRequestCard({
    super.key,
    required this.request,
  });

  static const cardKey = Key('parking-request-card');

  final ParkingRequestSummary request;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: cardKey,
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0.0),
                    child: SvgPicture.asset(
                      'assets/images/map.svg',
                      width: 30.0,
                      height: 30.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel(context),
                          style:
                              FlutterFlowTheme.of(context).labelLarge.override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontStyle,
                                    ),
                                    color: _statusColor(context),
                                    fontSize: 15.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontStyle,
                                  ),
                        ),
                        Flexible(
                          child: Text(
                            valueOrDefault<String>(
                              request.address,
                              'No address',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ].divide(const SizedBox(width: 12.0)),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: SvgPicture.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/images/Trailing_element_dark.svg'
                    : 'assets/images/Trailing_element.svg',
                width: 24.0,
                height: 24.0,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context) {
    final localization = FFLocalizations.of(context);
    return switch (request.status) {
      ParkingRequestStatus.pending =>
        localization.getText('5ascx5of' /* Under moderation */),
      ParkingRequestStatus.approved =>
        localization.getText('b4fc9la0' /* Accepted */),
      ParkingRequestStatus.rejected =>
        localization.getText('rq1fdjm3' /* Rejected */),
    };
  }

  Color? _statusColor(BuildContext context) => switch (request.status) {
        ParkingRequestStatus.pending => null,
        ParkingRequestStatus.approved => FlutterFlowTheme.of(context).accent1,
        ParkingRequestStatus.rejected => FlutterFlowTheme.of(context).accent2,
      };
}
