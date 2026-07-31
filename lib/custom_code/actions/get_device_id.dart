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

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import '/features/referrals/referral_device_identity.dart';

const _deviceIdentityChannel = MethodChannel('js_truck_park/device_identity');

Future<String> getDeviceId() async {
  try {
    if (Platform.isAndroid) {
      final androidId =
          await _deviceIdentityChannel.invokeMethod<String>('getAndroidId');
      return normalizeReferralDeviceId(
        platform: ReferralDevicePlatform.android,
        value: androidId,
      );
    }
    if (Platform.isIOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      return normalizeReferralDeviceId(
        platform: ReferralDevicePlatform.ios,
        value: iosInfo.identifierForVendor,
      );
    }
  } catch (error) {
    debugPrint(
      'Device identity lookup failed '
      '[$referralDeviceIdentityReleaseMarker]: ${error.runtimeType}',
    );
  }

  return '';
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
