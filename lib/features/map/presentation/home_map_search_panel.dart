import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../custom_code/widgets/bottom_spacer.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../../../flutter_flow/flutter_flow_util.dart';
import 'map_search_result_item.dart';

typedef MapSearchQueryCallback = Future<void> Function(String query);
typedef MapSearchResultCallback = Future<void> Function(
  MapSearchResultItem result,
);
typedef MapSearchAsyncAction = Future<void> Function();

class HomeMapSearchPanel extends StatelessWidget {
  const HomeMapSearchPanel({
    super.key,
    required this.maxHeight,
    required this.textController,
    required this.focusNode,
    required this.isSearching,
    required this.results,
    required this.isFilterApplied,
    required this.onQueryChanged,
    required this.onClear,
    required this.onResultSelected,
    required this.onFilterSelected,
    required this.onProfileSelected,
    this.validator,
  });

  static const searchFieldKey = Key('home-map-search-field');
  static const filterButtonKey = Key('home-map-filter-button');
  static const profileButtonKey = Key('home-map-profile-button');
  static const debounceKey = 'home-map-search-panel';
  static const debounceDuration = Duration(milliseconds: 500);

  final double maxHeight;
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isSearching;
  final List<MapSearchResultItem> results;
  final bool isFilterApplied;
  final MapSearchQueryCallback onQueryChanged;
  final VoidCallback onClear;
  final MapSearchResultCallback onResultSelected;
  final MapSearchAsyncAction onFilterSelected;
  final VoidCallback onProfileSelected;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) => Align(
        alignment: const AlignmentDirectional(0.0, 1.0),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildDragHandle(context),
              if (isSearching) _buildResults(context),
              _buildControls(context),
            ],
          ),
        ),
      );

  Widget _buildDragHandle(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
        child: GestureDetector(
          onVerticalDragEnd: (_) {
            textController.clear();
            onClear();
          },
          child: Container(
            width: 36.0,
            height: 5.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).divider,
              borderRadius: BorderRadius.circular(24.0),
            ),
          ),
        ),
      );

  Widget _buildResults(BuildContext context) => Flexible(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2.0),
            itemBuilder: (context, index) {
              final result = results[index];
              return GestureDetector(
                key: ValueKey('home-map-search-result-${result.id}'),
                onTap: () => onResultSelected(result),
                onVerticalDragEnd: (_) {
                  textController.clear();
                  onClear();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valueOrDefault<String>(result.address, 'No address'),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            fontSize: 17.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                    Divider(
                      thickness: 2.0,
                      color: FlutterFlowTheme.of(context).checksFormsButtons,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

  Widget _buildControls(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding:
                const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 20.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40.0,
                    child: TextFormField(
                      key: searchFieldKey,
                      controller: textController,
                      focusNode: focusNode,
                      onChanged: (_) => EasyDebounce.debounce(
                        debounceKey,
                        debounceDuration,
                        () => onQueryChanged(textController.text),
                      ),
                      autofocus: false,
                      enabled: true,
                      obscureText: false,
                      decoration: _searchDecoration(context),
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            font: GoogleFonts.roboto(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyLarge
                                  .fontStyle,
                            ),
                            fontSize: 17.0,
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
                      validator: validator,
                    ),
                  ),
                ),
                _buildFilterButton(context),
                _buildProfileButton(context),
              ],
            ),
          ),
          const BottomSpacer(width: double.infinity, height: 10.0),
        ],
      );

  InputDecoration _searchDecoration(BuildContext context) => InputDecoration(
        isDense: true,
        labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
              font: GoogleFonts.roboto(
                fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
              ),
              color: FlutterFlowTheme.of(context).searchMapsHinit,
              letterSpacing: 0.0,
              fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
            ),
        hintText: FFLocalizations.of(context).getText(
          '601bzdk7' /* Search Maps */,
        ),
        hintStyle: FlutterFlowTheme.of(context).labelLarge.override(
              font: GoogleFonts.roboto(
                fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
              ),
              color: const Color(0xFF6C6C6C),
              fontSize: 17.0,
              letterSpacing: 0.0,
              fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
            ),
        enabledBorder: _inputBorder(const Color(0x00000000)),
        focusedBorder: _inputBorder(const Color(0x00000000)),
        errorBorder: _inputBorder(FlutterFlowTheme.of(context).error),
        focusedErrorBorder: _inputBorder(FlutterFlowTheme.of(context).error),
        filled: true,
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        contentPadding:
            const EdgeInsetsDirectional.fromSTEB(6.0, 0.0, 0.0, 0.0),
        prefixIcon: const Icon(
          FFIcons.kicnSearch,
          color: Color(0xFF6C6C6C),
          size: 20.0,
        ),
        suffixIcon: textController.text.isNotEmpty
            ? InkWell(
                onTap: () {
                  textController.clear();
                  onClear();
                },
                child: Icon(
                  Icons.clear,
                  color: FlutterFlowTheme.of(context).searchMapsHinit,
                  size: 22.0,
                ),
              )
            : null,
      );

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 1.0),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10.0),
          bottomLeft: Radius.circular(10.0),
        ),
      );

  Widget _buildFilterButton(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 10.0, 0.0),
        child: InkWell(
          key: filterButtonKey,
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            textController.clear();
            onClear();
            await onFilterSelected();
          },
          child: Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            child: Align(
              alignment: const AlignmentDirectional(0.0, 0.0),
              child: Icon(
                FFIcons.ksetting4,
                color: isFilterApplied
                    ? FlutterFlowTheme.of(context).primary
                    : const Color(0xFF8E8E93),
                size: 20.0,
              ),
            ),
          ),
        ),
      );

  Widget _buildProfileButton(BuildContext context) => InkWell(
        key: profileButtonKey,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onProfileSelected,
        child: Container(
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0.0),
            child: SvgPicture.asset(
              'assets/images/menu.svg',
              width: 24.0,
              height: 24.0,
              fit: BoxFit.none,
            ),
          ),
        ),
      );
}
