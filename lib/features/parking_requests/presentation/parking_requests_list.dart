import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../application/parking_requests_controller.dart';
import '../domain/parking_request_summary.dart';
import 'parking_request_card.dart';

class ParkingRequestsList extends StatelessWidget {
  const ParkingRequestsList({
    super.key,
    required this.state,
    required this.onRequestSelected,
    required this.onRetry,
  });

  static const loadingKey = Key('parking-requests-loading');
  static const failureKey = Key('parking-requests-failure');
  static const emptyKey = Key('parking-requests-empty');
  static const listKey = Key('parking-requests-list');

  final ParkingRequestsState state;
  final ValueChanged<ParkingRequestSummary> onRequestSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.phase == ParkingRequestsLoadPhase.idle ||
        state.phase == ParkingRequestsLoadPhase.loading) {
      return _loading(context, key: loadingKey);
    }

    if (state.phase == ParkingRequestsLoadPhase.failure) {
      return InkWell(
        key: failureKey,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onRetry,
        child: _loading(context),
      );
    }

    if (state.requests.isEmpty) {
      return _empty(context);
    }

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: ListView.separated(
        key: listKey,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: state.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8.0),
        itemBuilder: (context, index) {
          final request = state.requests[index];
          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => onRequestSelected(request),
            child: ParkingRequestCard(
              key: ValueKey(request.id),
              request: request,
            ),
          );
        },
      ),
    );
  }

  Widget _loading(BuildContext context, {Key? key}) => Center(
        child: SizedBox(
          key: key,
          width: 50.0,
          height: 50.0,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),
      );

  Widget _empty(BuildContext context) => Padding(
        key: emptyKey,
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 150.0, 0.0, 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: SvgPicture.asset(
                'assets/images/map.svg',
                width: 96.0,
                height: 96.0,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              _emptyLabel(context),
              textAlign: state.status == ParkingRequestStatus.pending
                  ? TextAlign.center
                  : null,
              style: FlutterFlowTheme.of(context).labelLarge.override(
                    font: GoogleFonts.roboto(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight:
                        FlutterFlowTheme.of(context).labelLarge.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelLarge.fontStyle,
                  ),
            ),
          ].divide(const SizedBox(height: 16.0)),
        ),
      );

  String _emptyLabel(BuildContext context) {
    final localization = FFLocalizations.of(context);
    return switch (state.status) {
      ParkingRequestStatus.pending => localization.getText(
          'kt10y4th' /* Applications awaiting moderation will be shown here */,
        ),
      ParkingRequestStatus.approved => localization.getText(
          'u04tu3wa' /* Approved applications will be shown here */,
        ),
      ParkingRequestStatus.rejected => localization.getText(
          'd79wksx8' /* Rejected applications will be shown here */,
        ),
    };
  }
}
