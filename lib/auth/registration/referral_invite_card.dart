import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const referralInviteCardReleaseMarker = 'referral-invite-card-v1';

enum ReferralInviteStatus {
  empty,
  detectedAutomatically,
  addedManually,
}

class ReferralInviteCard extends StatelessWidget {
  const ReferralInviteCard({
    super.key,
    required this.status,
    required this.onPressed,
  });

  final ReferralInviteStatus status;
  final VoidCallback onPressed;

  bool get _hasLink => status != ReferralInviteStatus.empty;

  String _title(BuildContext context) {
    switch (status) {
      case ReferralInviteStatus.empty:
        return FFLocalizations.of(context).getText('haveReferralLink');
      case ReferralInviteStatus.detectedAutomatically:
        return FFLocalizations.of(context).getText('referralLinkFound');
      case ReferralInviteStatus.addedManually:
        return FFLocalizations.of(context).getText('referralLinkAdded');
    }
  }

  String _description(BuildContext context) {
    switch (status) {
      case ReferralInviteStatus.empty:
        return FFLocalizations.of(context).getText('referralDiscountHint');
      case ReferralInviteStatus.detectedAutomatically:
        return FFLocalizations.of(context).getText(
          'referralAutomaticDetectedHint',
        );
      case ReferralInviteStatus.addedManually:
        return FFLocalizations.of(context).getText(
          'referralManualPendingHint',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      key: const ValueKey(referralInviteCardReleaseMarker),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _hasLink ? theme.primary : theme.alternate,
          width: _hasLink ? 1.2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _hasLink ? Icons.check_rounded : Icons.card_giftcard_rounded,
              color: theme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(context),
                  style: theme.titleSmall.override(
                    font: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                    color: theme.primaryText,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _description(context),
                  style: theme.bodySmall.override(
                    font: GoogleFonts.roboto(),
                    color: theme.secondaryText,
                    letterSpacing: 0,
                    lineHeight: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      FFLocalizations.of(context).getText(
                        _hasLink
                            ? 'changeReferralLink'
                            : 'pasteReferralLinkAction',
                      ),
                      style: theme.labelLarge.override(
                        font: GoogleFonts.roboto(fontWeight: FontWeight.w600),
                        color: theme.primary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
