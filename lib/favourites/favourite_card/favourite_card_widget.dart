import '/features/favorites/data/favorites_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'favourite_card_model.dart';
export 'favourite_card_model.dart';

class FavouriteCardWidget extends StatefulWidget {
  const FavouriteCardWidget({
    super.key,
    required this.favorite,
  });

  final FavoriteParking? favorite;

  @override
  State<FavouriteCardWidget> createState() => _FavouriteCardWidgetState();
}

class _FavouriteCardWidgetState extends State<FavouriteCardWidget> {
  late FavouriteCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FavouriteCardModel());

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
        padding: EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (context) {
                      final primaryPhotoUrl = widget.favorite?.primaryPhotoUrl;
                      if (primaryPhotoUrl != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            primaryPhotoUrl,
                            width: 56.0,
                            height: 56.0,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        return Container(
                          width: 56.0,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Icon(
                            Icons.no_photography,
                            color: FlutterFlowTheme.of(context).checkBoxes,
                            size: 50.0,
                          ),
                        );
                      }
                    },
                  ),
                  Flexible(
                    child: Text(
                      valueOrDefault<String>(
                        widget.favorite?.address,
                        'No address',
                      ),
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
                ].divide(SizedBox(width: 16.0)),
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
          ].divide(SizedBox(width: 16.0)),
        ),
      ),
    );
  }
}
