import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'invite_friends_dialog_model.dart';
export 'invite_friends_dialog_model.dart';

class InviteFriendsDialogWidget extends StatefulWidget {
  const InviteFriendsDialogWidget({
    super.key,
    this.ref,
    this.linkLoader,
  });

  final String? ref;
  final Future<String> Function()? linkLoader;

  @override
  State<InviteFriendsDialogWidget> createState() =>
      _InviteFriendsDialogWidgetState();
}

class _InviteFriendsDialogWidgetState extends State<InviteFriendsDialogWidget> {
  late InviteFriendsDialogModel _model;
  String? _ref;
  bool _isLoading = false;
  bool _hasError = false;

  bool get _hasLink => _ref?.trim().isNotEmpty ?? false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InviteFriendsDialogModel());
    _ref = widget.ref;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLink) {
        safeSetState(() {});
        return;
      }
      unawaited(_loadLink());
    });
  }

  Future<void> _loadLink() async {
    if (_isLoading) {
      return;
    }
    final loader = widget.linkLoader;
    if (loader == null) {
      safeSetState(() => _hasError = true);
      return;
    }

    safeSetState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final link = (await loader()).trim();
      if (link.isEmpty) {
        throw StateError('Invite link is empty');
      }
      if (!mounted) {
        return;
      }
      safeSetState(() => _ref = link);
    } catch (_) {
      if (!mounted) {
        return;
      }
      safeSetState(() => _hasError = true);
    } finally {
      if (mounted) {
        safeSetState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.0, 40.0, 16.0, 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0.0),
                  child: SvgPicture.asset(
                    'assets/images/profile-add.svg',
                    width: 80.0,
                    height: 80.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                child: Text(
                  FFLocalizations.of(context).getText(
                    '0pjee4u7' /* Invite friends */,
                  ),
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                        font: GoogleFonts.roboto(
                          fontWeight: FontWeight.w500,
                          fontStyle:
                              FlutterFlowTheme.of(context).titleLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).titleLarge.fontStyle,
                      ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                child: Text(
                  FFLocalizations.of(context).getText(
                    'hr61a3eu' /* Invite a friend and get a disc... */,
                  ),
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).labelLarge.override(
                        font: GoogleFonts.roboto(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelLarge
                              .fontWeight,
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
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: _hasLink
                      ? () async {
                          await Clipboard.setData(ClipboardData(text: _ref!));
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                FFLocalizations.of(context).getVariableText(
                                  enText: 'Link copied',
                                  ruText: 'Ссылка скопирована',
                                ),
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                              ),
                              duration: Duration(milliseconds: 4000),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).secondary,
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    height: 56.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).checksFormsButtons,
                      ),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                      child: _isLoading
                          ? Center(
                              child: SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            )
                          : _hasError
                              ? Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        FFLocalizations.of(context)
                                            .getVariableText(
                                          enText:
                                              'Could not create the link. Try again.',
                                          ruText:
                                              'Не удалось создать ссылку. Повторите попытку.',
                                        ),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: FFLocalizations.of(context)
                                          .getVariableText(
                                        enText: 'Try again',
                                        ruText: 'Повторить',
                                      ),
                                      onPressed: _loadLink,
                                      icon: Icon(
                                        Icons.refresh_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primary,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        valueOrDefault<String>(_ref, 'Link'),
                                        style: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              font: GoogleFonts.roboto(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: SvgPicture.asset(
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 'assets/images/copy-dark.svg'
                                            : 'assets/images/copy-light.svg',
                                        width: 20.0,
                                        height: 20.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FFButtonWidget(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      text: FFLocalizations.of(context).getText(
                        'fl7o38kq' /* Cancel */,
                      ),
                      options: FFButtonOptions(
                        height: 56.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).checksFormsButtons,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.roboto(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).accent4,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) => FFButtonWidget(
                        onPressed: _hasLink
                            ? () async {
                                await Share.share(
                                  _ref!,
                                  sharePositionOrigin:
                                      getWidgetBoundingBox(context),
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.pop(context);
                              }
                            : null,
                        text: FFLocalizations.of(context).getText(
                          'j5yv5qwi' /* Share */,
                        ),
                        options: FFButtonOptions(
                          height: 56.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                ].divide(SizedBox(width: 8.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
