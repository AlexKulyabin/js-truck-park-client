import 'dart:async';

import '/auth/supabase_auth/auth_util.dart';
import '/features/favorites/application/favorites_controller.dart';
import '/features/favorites/data/supabase_favorites_repository.dart';
import '/features/favorites/domain/favorite_parking_summary.dart';
import '/features/favorites/domain/favorites_repository.dart';
import '/features/favorites/presentation/favorite_parking_navigation.dart';
import '/features/favorites/presentation/favorites_list.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'favourites_model.dart';
export 'favourites_model.dart';

class FavouritesWidget extends StatefulWidget {
  const FavouritesWidget({
    super.key,
    this.repository,
    this.userId,
  });

  final FavoritesRepository? repository;
  final String? userId;

  static String routeName = 'Favourites';
  static String routePath = '/favourites';

  @override
  State<FavouritesWidget> createState() => _FavouritesWidgetState();
}

class _FavouritesWidgetState extends State<FavouritesWidget> {
  late FavouritesModel _model;
  late final FavoritesController _favoritesController;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FavouritesModel());
    _favoritesController = FavoritesController(
      repository: widget.repository ?? SupabaseFavoritesRepository(),
      userId: widget.userId ?? currentUserUid,
    )..addListener(_onFavoritesChanged);
    unawaited(_favoritesController.load());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _favoritesController
      ..removeListener(_onFavoritesChanged)
      ..dispose();
    _model.dispose();

    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openFavorite(FavoriteParkingSummary favorite) async {
    await context.pushNamed(
      HomePageWidget.routeName,
      queryParameters: buildFavoriteParkingQueryParameters(favorite),
    );
    if (mounted) {
      unawaited(_favoritesController.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _favoritesController.state;
    if (state.phase == FavoritesLoadPhase.idle ||
        state.phase == FavoritesLoadPhase.loading ||
        state.phase == FavoritesLoadPhase.failure) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: FavoritesList(
          state: state,
          onFavoriteSelected: _openFavorite,
          onRetry: () => unawaited(_favoritesController.retry()),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Stack(
                alignment: const AlignmentDirectional(-1.0, 0.0),
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Flexible(
                        child: Align(
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0,
                              11.0,
                              0.0,
                              11.0,
                            ),
                            child: Text(
                              FFLocalizations.of(context).getText(
                                'visdd4n6' /* Favourites */,
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    fontSize: 17.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: const AlignmentDirectional(-1.0, 0.0),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        4.0,
                        0.0,
                        0.0,
                        0.0,
                      ),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: context.safePop,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            4.0,
                            4.0,
                            4.0,
                            4.0,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_outlined,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: FavoritesList(
                  state: state,
                  onFavoriteSelected: _openFavorite,
                  onRetry: () => unawaited(_favoritesController.retry()),
                ),
              ),
            ].divide(const SizedBox(height: 16.0)),
          ),
        ),
      ),
    );
  }
}
