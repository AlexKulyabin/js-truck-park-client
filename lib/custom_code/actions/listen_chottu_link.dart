// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';

import 'package:chottu_link/chottu_link.dart';
import '/features/referrals/referral_links.dart';

StreamSubscription<String>? _chottuLinkSubscription;

Future listenChottuLink() async {
  if (_chottuLinkSubscription != null) {
    return;
  }

  _chottuLinkSubscription = ChottuLink.onLinkReceived.listen((String link) {
    final refCode = referralCodeFromUrl(link);

    if (refCode != null) {
      FFAppState().update(() {
        FFAppState().tempReferralCode = refCode;
      });
    }
  });
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
