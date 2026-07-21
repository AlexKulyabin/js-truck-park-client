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
import 'package:chottu_link/dynamic_link/cl_dynamic_link_behaviour.dart';
import 'package:chottu_link/dynamic_link/cl_dynamic_link_parameters.dart';

Future<String> createReferralLink(String referralCode) async {
  final completer = Completer<String>();

  try {
    final parameters = CLDynamicLinkParameters(
      link: Uri.parse("https://js-truck-park.web.app/?ref=$referralCode"),
      domain: "js-truck-park.chottu.link",
      androidBehaviour: CLDynamicLinkBehaviour.app,
      iosBehaviour: CLDynamicLinkBehaviour.app,
    );

    ChottuLink.createDynamicLink(
      parameters: parameters,
      onSuccess: (link) {
        if (!completer.isCompleted) completer.complete(link);
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete("ERROR: ${error.message}");
        }
      },
    );
  } catch (e) {
    if (!completer.isCompleted) {
      completer.complete("EXCEPTION: $e");
    }
  }

  return completer.future.timeout(
    Duration(seconds: 10),
    onTimeout: () => "TIMEOUT: no response from ChottuLink",
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
