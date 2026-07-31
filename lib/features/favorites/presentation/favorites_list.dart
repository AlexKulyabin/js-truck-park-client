import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import '../application/favorites_controller.dart';
import '../domain/favorite_parking_summary.dart';
import 'favorite_parking_card.dart';

class FavoritesList extends StatelessWidget {
  const FavoritesList({
    super.key,
    required this.state,
    required this.onFavoriteSelected,
    required this.onRetry,
  });

  static const loadingKey = Key('favorites-list-loading');
  static const failureKey = Key('favorites-list-failure');
  static const emptyKey = Key('favorites-list-empty');
  static const listKey = Key('favorites-list-loaded');

  final FavoritesState state;
  final ValueChanged<FavoriteParkingSummary> onFavoriteSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.phase == FavoritesLoadPhase.idle ||
        state.phase == FavoritesLoadPhase.loading) {
      return _loading(context, key: loadingKey);
    }

    if (state.phase == FavoritesLoadPhase.failure) {
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

    if (state.favorites.isEmpty) {
      return _empty(context);
    }

    return ListView.separated(
      key: listKey,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemCount: state.favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        final favorite = state.favorites[index];
        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => onFavoriteSelected(favorite),
          child: FavoriteParkingCard(
            key: ValueKey(favorite.favoriteRecordId),
            favorite: favorite,
          ),
        );
      },
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
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: SvgPicture.asset(
                'assets/images/favorite_blue.svg',
                width: 96.0,
                height: 96.0,
                fit: BoxFit.cover,
              ),
            ),
            Text(
              FFLocalizations.of(context).getText(
                'u0idlh6r' /* Your favorite parking spots will be displayed here */,
              ),
              textAlign: TextAlign.center,
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
}
