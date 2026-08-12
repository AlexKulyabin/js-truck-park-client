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

import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/auth/domain/phone_number.dart';

Future<bool> verifyOtp(String rawPhoneNumber, String otpCode) async {
  final formattedPhone = normalizePhoneNumberToE164(rawPhoneNumber);
  if (formattedPhone == null) {
    debugPrint('OTP verification failed: invalid_phone_format');
    return false;
  }

  try {
    final res = await Supabase.instance.client.auth.verifyOTP(
      phone: formattedPhone,
      token: otpCode,
      type: OtpType.sms,
    );

    if (res.session != null) {
      return true;
    }

    return false;
  } on AuthException catch (error) {
    debugPrint(
      'OTP verification failed: status=${error.statusCode ?? 'unknown'}, '
      'code=${error.code ?? 'unknown'}',
    );
    return false;
  } catch (_) {
    debugPrint('OTP verification failed: client_error');
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
