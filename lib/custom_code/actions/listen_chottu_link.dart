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

import 'package:chottu_link/chottu_link.dart';

Future listenChottuLink() async {
  ChottuLink.onLinkReceived.listen((String link) {
    final uri = Uri.tryParse(link);
    final refCode = uri?.queryParameters['ref'];

    if (refCode != null && refCode.isNotEmpty) {
      FFAppState().update(() {
        FFAppState().tempReferralCode = refCode;
      });
    }
  });
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
