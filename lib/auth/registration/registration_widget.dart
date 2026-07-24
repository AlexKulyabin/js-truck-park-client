import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'registration_model.dart';
export 'registration_model.dart';

class RegistrationWidget extends StatefulWidget {
  const RegistrationWidget({super.key});

  static String routeName = 'Registration';
  static String routePath = '/registration';

  @override
  State<RegistrationWidget> createState() => _RegistrationWidgetState();
}

class _RegistrationWidgetState extends State<RegistrationWidget> {
  late RegistrationModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegistrationModel());

    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 40.0, 16.0, 60.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          '7txhp7v1' /* Registration */,
                        ),
                        style: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .override(
                              font: GoogleFonts.roboto(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .fontStyle,
                              lineHeight: 1.0,
                            ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 40.0),
                      child: Text(
                        FFLocalizations.of(context).getText(
                          '0inqa3r5' /* Fill in the information about ... */,
                        ),
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.roboto(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                              lineHeight: 1.4,
                            ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                      child: Builder(
                        builder: (context) {
                          if (_model.photo == null ||
                              (_model.photo?.bytes?.isEmpty ?? true)) {
                            return InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                final selectedMedia =
                                    await selectMediaWithSourceBottomSheet(
                                  context: context,
                                  maxWidth: 510.00,
                                  maxHeight: 510.00,
                                  imageQuality: 80,
                                  allowPhoto: true,
                                );
                                if (selectedMedia != null &&
                                    selectedMedia.every((m) =>
                                        validateFileFormat(
                                            m.storagePath, context))) {
                                  safeSetState(() => _model
                                      .isDataUploading_uploadData22 = true);
                                  var selectedUploadedFiles =
                                      <FFUploadedFile>[];

                                  try {
                                    selectedUploadedFiles = selectedMedia
                                        .map((m) => FFUploadedFile(
                                              name:
                                                  m.storagePath.split('/').last,
                                              bytes: m.bytes,
                                              height: m.dimensions?.height,
                                              width: m.dimensions?.width,
                                              blurHash: m.blurHash,
                                              originalFilename:
                                                  m.originalFilename,
                                            ))
                                        .toList();
                                  } finally {
                                    _model.isDataUploading_uploadData22 = false;
                                  }
                                  if (selectedUploadedFiles.length ==
                                      selectedMedia.length) {
                                    safeSetState(() {
                                      _model.uploadedLocalFile_uploadData22 =
                                          selectedUploadedFiles.first;
                                    });
                                  } else {
                                    safeSetState(() {});
                                    return;
                                  }
                                }

                                if (_model.uploadedLocalFile_uploadData22 !=
                                        null &&
                                    (_model.uploadedLocalFile_uploadData22.bytes
                                            ?.isNotEmpty ??
                                        false)) {
                                  _model.photo =
                                      _model.uploadedLocalFile_uploadData22;
                                  safeSetState(() {});
                                } else {
                                  return;
                                }
                              },
                              child: Stack(
                                alignment: AlignmentDirectional(1.0, 1.0),
                                children: [
                                  Container(
                                    width: 100.0,
                                    height: 100.0,
                                    decoration: BoxDecoration(),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(0.0),
                                      child: SvgPicture.asset(
                                        'assets/images/profile.svg',
                                        width: 100.0,
                                        height: 100.0,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(0.0),
                                    child: SvgPicture.asset(
                                      'assets/images/edit_photo.svg',
                                      width: 34.0,
                                      height: 34.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Stack(
                              alignment: AlignmentDirectional(1.0, 1.0),
                              children: [
                                Container(
                                  width: 100.0,
                                  height: 100.0,
                                  decoration: BoxDecoration(),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99.0),
                                    child: Image.memory(
                                      _model.photo?.bytes ??
                                          Uint8List.fromList([]),
                                      width: 100.0,
                                      height: 100.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  splashColor: Colors.transparent,
                                  focusColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  onTap: () async {
                                    final selectedMedia =
                                        await selectMediaWithSourceBottomSheet(
                                      context: context,
                                      maxWidth: 510.00,
                                      maxHeight: 510.00,
                                      imageQuality: 80,
                                      allowPhoto: true,
                                    );
                                    if (selectedMedia != null &&
                                        selectedMedia.every((m) =>
                                            validateFileFormat(
                                                m.storagePath, context))) {
                                      safeSetState(() => _model
                                          .isDataUploading_uploadData2g = true);
                                      var selectedUploadedFiles =
                                          <FFUploadedFile>[];

                                      try {
                                        selectedUploadedFiles = selectedMedia
                                            .map((m) => FFUploadedFile(
                                                  name: m.storagePath
                                                      .split('/')
                                                      .last,
                                                  bytes: m.bytes,
                                                  height: m.dimensions?.height,
                                                  width: m.dimensions?.width,
                                                  blurHash: m.blurHash,
                                                  originalFilename:
                                                      m.originalFilename,
                                                ))
                                            .toList();
                                      } finally {
                                        _model.isDataUploading_uploadData2g =
                                            false;
                                      }
                                      if (selectedUploadedFiles.length ==
                                          selectedMedia.length) {
                                        safeSetState(() {
                                          _model.uploadedLocalFile_uploadData2g =
                                              selectedUploadedFiles.first;
                                        });
                                      } else {
                                        safeSetState(() {});
                                        return;
                                      }
                                    }

                                    if (_model.uploadedLocalFile_uploadData2g !=
                                            null &&
                                        (_model.uploadedLocalFile_uploadData2g
                                                .bytes?.isNotEmpty ??
                                            false)) {
                                      _model.photo =
                                          _model.uploadedLocalFile_uploadData2g;
                                      safeSetState(() {});
                                    } else {
                                      return;
                                    }
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0.0),
                                    child: SvgPicture.asset(
                                      'assets/images/edit_photo.svg',
                                      width: 34.0,
                                      height: 34.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _model.nameTextController,
                        focusNode: _model.nameFocusNode,
                        onChanged: (_) => EasyDebounce.debounce(
                          '_model.nameTextController',
                          Duration(milliseconds: 2000),
                          () async {
                            safeSetState(() {});
                          },
                        ),
                        autofocus: false,
                        enabled: true,
                        textCapitalization: TextCapitalization.none,
                        obscureText: false,
                        decoration: InputDecoration(
                          isDense: true,
                          labelStyle: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
                                font: GoogleFonts.roboto(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                          hintText: FFLocalizations.of(context).getText(
                            'bt0z2i9a' /* Name  */,
                          ),
                          hintStyle: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
                                font: GoogleFonts.roboto(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x00000000),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x00000000),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: FlutterFlowTheme.of(context).error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          contentPadding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 19.0, 16.0, 19.0),
                        ),
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
                        cursorColor: FlutterFlowTheme.of(context).primaryText,
                        enableInteractiveSelection: true,
                        validator: _model.nameTextControllerValidator
                            .asValidator(context),
                        inputFormatters: [
                          if (!isAndroid && !isiOS)
                            TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                              return TextEditingValue(
                                selection: newValue.selection,
                                text: newValue.text
                                    .toCapitalization(TextCapitalization.none),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    FFButtonWidget(
                      onPressed: ((_model.photo == null ||
                                  (_model.photo?.bytes?.isEmpty ?? true)) ||
                              (_model.nameTextController.text == null ||
                                  _model.nameTextController.text == ''))
                          ? null
                          : () async {
                              if (_model.photo != null &&
                                  (_model.photo?.bytes?.isNotEmpty ?? false)) {
                                {
                                  safeSetState(() => _model
                                      .isDataUploading_uploadData9f = true);
                                  var selectedUploadedFiles =
                                      <FFUploadedFile>[];
                                  var selectedMedia = <SelectedFile>[];
                                  var downloadUrls = <String>[];
                                  try {
                                    selectedUploadedFiles =
                                        _model.photo!.bytes!.isNotEmpty
                                            ? [_model.photo!]
                                            : <FFUploadedFile>[];
                                    selectedMedia =
                                        selectedFilesFromUploadedFiles(
                                      selectedUploadedFiles,
                                      storageFolderPath:
                                          'users/${currentUserUid}',
                                    );
                                    downloadUrls =
                                        await uploadSupabaseStorageFiles(
                                      bucketName: 'avatars',
                                      selectedFiles: selectedMedia,
                                    );
                                  } finally {
                                    _model.isDataUploading_uploadData9f = false;
                                  }
                                  if (selectedUploadedFiles.length ==
                                          selectedMedia.length &&
                                      downloadUrls.length ==
                                          selectedMedia.length) {
                                    safeSetState(() {
                                      _model.uploadedLocalFile_uploadData9f =
                                          selectedUploadedFiles.first;
                                      _model.uploadedFileUrl_uploadData9f =
                                          downloadUrls.first;
                                    });
                                  } else {
                                    safeSetState(() {});
                                    return;
                                  }
                                }

                                await UsersTable().update(
                                  data: {
                                    'full_name': _model.nameTextController.text,
                                    'avatar_url':
                                        _model.uploadedFileUrl_uploadData9f,
                                    'last_device_id': FFAppState().deviceId,
                                  },
                                  matchingRows: (rows) => rows.eqOrNull(
                                    'id',
                                    currentUserUid,
                                  ),
                                );
                              } else {
                                await UsersTable().update(
                                  data: {
                                    'full_name': _model.nameTextController.text,
                                    'last_device_id': FFAppState().deviceId,
                                  },
                                  matchingRows: (rows) => rows.eqOrNull(
                                    'id',
                                    currentUserUid,
                                  ),
                                );
                              }

                              if (FFAppState().tempReferralCode != null &&
                                  FFAppState().tempReferralCode != '') {
                                _model.apiResult8fn =
                                    await ProcessReferralCall.call(
                                  refCode: FFAppState().tempReferralCode,
                                  refereeId: currentUserUid,
                                  deviceId: FFAppState().deviceId,
                                  userToken: currentJwtToken,
                                );

                                if ((_model.apiResult8fn?.succeeded ?? true)) {
                                  FFAppState().tempReferralCode = '';
                                  safeSetState(() {});
                                  if (functions.isReferralApiSuccess(
                                          (_model.apiResult8fn?.jsonBody ?? '')
                                              .toString()) !=
                                      true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          getJsonField(
                                            (_model.apiResult8fn?.jsonBody ??
                                                ''),
                                            r'''$.message''',
                                          ).toString(),
                                          style: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                          ),
                                        ),
                                        duration: Duration(milliseconds: 4000),
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .accent2,
                                      ),
                                    );
                                  }
                                }
                              }

                              context.pushNamed(HomePageWidget.routeName);

                              safeSetState(() {});
                            },
                      text: FFLocalizations.of(context).getText(
                        'tmbsyxys' /* Done */,
                      ),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
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
                                  color: FlutterFlowTheme.of(context).info,
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
                        disabledColor:
                            FlutterFlowTheme.of(context).inactiveButton,
                        disabledTextColor:
                            FlutterFlowTheme.of(context).inactiveText,
                      ),
                    ),
                  ].divide(SizedBox(height: 16.0)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
