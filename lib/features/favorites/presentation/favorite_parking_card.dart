import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../domain/favorite_parking_summary.dart';

class FavoriteParkingCard extends StatelessWidget {
  const FavoriteParkingCard({
    super.key,
    required this.favorite,
  });

  final FavoriteParkingSummary favorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (favorite.thumbnailUrl case final thumbnailUrl?)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        thumbnailUrl,
                        width: 56.0,
                        height: 56.0,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 56.0,
                      height: 56.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        Icons.no_photography,
                        color: FlutterFlowTheme.of(context).checkBoxes,
                        size: 50.0,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      valueOrDefault<String>(favorite.address, 'No address'),
                      maxLines: 2,
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ].divide(const SizedBox(width: 16.0)),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: SvgPicture.asset(
                'assets/images/favorite_blue.svg',
                width: 24.0,
                height: 24.0,
                fit: BoxFit.cover,
              ),
            ),
          ].divide(const SizedBox(width: 16.0)),
        ),
      ),
    );
  }
}
