import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const referralManualLinkFallbackReleaseMarker =
    'referral-manual-link-fallback-v1';

class ReferralLinkInputSheet extends StatefulWidget {
  const ReferralLinkInputSheet({
    super.key,
    required this.captureLink,
  });

  final Future<bool> Function(String link) captureLink;

  @override
  State<ReferralLinkInputSheet> createState() => _ReferralLinkInputSheetState();
}

class _ReferralLinkInputSheetState extends State<ReferralLinkInputSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final value = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (value == null || value.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _controller.text = value;
      _controller.selection = TextSelection.collapsed(offset: value.length);
      _errorText = null;
    });
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = FFLocalizations.of(context).getText(
          'referralLinkRequired',
        );
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    var captured = false;
    try {
      captured = await widget.captureLink(value);
    } catch (_) {
      captured = false;
    }
    if (!mounted) {
      return;
    }
    if (captured) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorText = FFLocalizations.of(context).getText(
        'invalidReferralLink',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DecoratedBox(
        key: const ValueKey(referralManualLinkFallbackReleaseMarker),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'inviteLinkSheetTitle',
                        ),
                        style: theme.titleMedium.override(
                          font: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                          ),
                          color: theme.primaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  FFLocalizations.of(context).getText(
                    'inviteLinkSheetDescription',
                  ),
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.roboto(),
                    color: theme.secondaryText,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                  onSubmitted: (_) {
                    if (!_isSubmitting) {
                      _submit();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: FFLocalizations.of(context).getText(
                      'referralLinkLabel',
                    ),
                    errorText: _errorText,
                    filled: true,
                    fillColor: theme.primaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _paste,
                  icon: const Icon(Icons.content_paste_rounded, size: 19),
                  label: Text(
                    FFLocalizations.of(context).getText(
                      'pasteReferralLink',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primary,
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: theme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: theme.labelLarge.override(
                      font: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FFButtonWidget(
                  onPressed: _isSubmitting ? null : _submit,
                  text: FFLocalizations.of(context).getText(
                    'applyReferralLink',
                  ),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 52,
                    color: theme.primary,
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.roboto(),
                      color: theme.info,
                      letterSpacing: 0.0,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
