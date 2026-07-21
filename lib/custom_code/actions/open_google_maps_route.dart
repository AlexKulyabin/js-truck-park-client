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

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/flutter_flow/flutter_flow_util.dart'; // дает тип LatLng FlutterFlow

Future<void> openGoogleMapsRoute(LatLng destination) async {
  final lat = destination.latitude;
  final lng = destination.longitude;

  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );

  // 1) В превью/на Web открываем в новой вкладке (чаще всего работает в тесте)
  if (kIsWeb) {
    await launchUrl(
      uri,
      webOnlyWindowName: '_blank', // новая вкладка
    );
    return;
  }

  // 2) На устройствах: пытаемся открыть внешнее приложение
  final can = await canLaunchUrl(uri);
  if (!can) {
    throw 'Не удалось открыть ссылку: $uri';
  }

  // Пытаемся открыть внешне (Google Maps), если не вышло — fallback во встроенный вебвью
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!ok) {
    await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,
    );
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
