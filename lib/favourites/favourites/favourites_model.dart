import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/features/favorites/data/favorites_service.dart';
import '/favourites/favourite_card/favourite_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'favourites_widget.dart' show FavouritesWidget;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FavouritesModel extends FlutterFlowModel<FavouritesWidget> {
  final favoritesService = FavoritesService();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
