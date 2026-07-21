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

Future<String> waitForReferralCode(int timeoutSeconds) async {
  final deadline = DateTime.now().add(Duration(seconds: timeoutSeconds));

  while (DateTime.now().isBefore(deadline)) {
    final current = FFAppState().tempReferralCode;
    if (current != null && current.isNotEmpty) {
      return current;
    }
    await Future.delayed(Duration(milliseconds: 200));
  }

  return FFAppState().tempReferralCode ?? '';
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
