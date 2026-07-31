import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../flutter_flow/custom_icons.dart';
import '../../../flutter_flow/flutter_flow_theme.dart';
import '../application/theme_controller.dart';

class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({super.key});

  static const toggleKey = Key('theme-mode-toggle');
  static const lightSelectionKey = Key('theme-mode-light-selection');
  static const darkSelectionKey = Key('theme-mode-dark-selection');

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final isDarkMode = controller.state.themeMode == ThemeMode.dark;

    return InkWell(
      key: toggleKey,
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => unawaited(
        controller.selectThemeMode(
          isDarkMode ? ThemeMode.light : ThemeMode.dark,
        ),
      ),
      child: Container(
        width: 118.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: const Color(0x1E767680),
          borderRadius: BorderRadius.circular(9.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: isDarkMode
              ? [
                  _unselectedIcon(
                    context,
                    icon: FFIcons.ksun,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      19.5,
                      0.0,
                      0.0,
                      0.0,
                    ),
                  ),
                  _selectedIcon(
                    context,
                    icon: FFIcons.kmoon,
                    key: darkSelectionKey,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0,
                      0.0,
                      2.0,
                      0.0,
                    ),
                  ),
                ]
              : [
                  _selectedIcon(
                    context,
                    icon: FFIcons.ksun,
                    key: lightSelectionKey,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      2.0,
                      0.0,
                      0.0,
                      0.0,
                    ),
                  ),
                  _unselectedIcon(
                    context,
                    icon: FFIcons.kmoon,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      0.0,
                      0.0,
                      19.5,
                      0.0,
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _selectedIcon(
    BuildContext context, {
    required IconData icon,
    required Key key,
    required EdgeInsetsDirectional padding,
  }) =>
      Padding(
        padding: padding,
        child: Container(
          key: key,
          width: 57.0,
          height: 24.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: const [
              BoxShadow(
                blurRadius: 8.0,
                color: Color(0x1F000000),
                offset: Offset(0.0, 3.0),
              ),
            ],
            borderRadius: BorderRadius.circular(7.0),
          ),
          child: Align(
            alignment: const AlignmentDirectional(0.0, 0.0),
            child: Icon(
              icon,
              color: FlutterFlowTheme.of(context).primaryText,
              size: 18.0,
            ),
          ),
        ),
      );

  Widget _unselectedIcon(
    BuildContext context, {
    required IconData icon,
    required EdgeInsetsDirectional padding,
  }) =>
      Padding(
        padding: padding,
        child: Icon(
          icon,
          color: FlutterFlowTheme.of(context).primaryText,
          size: 18.0,
        ),
      );
}
