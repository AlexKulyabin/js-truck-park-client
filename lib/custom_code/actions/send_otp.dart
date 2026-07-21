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

Future<bool> sendOtp(String rawPhoneNumber) async {
  try {
    // 1. Очистка: оставляем только цифры
    String cleanNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Логика замены 8 на 7 для СНГ
    if (cleanNumber.startsWith('8') && cleanNumber.length == 11) {
      cleanNumber = '7' + cleanNumber.substring(1);
    }

    // 3. Формат E.164 (с плюсом)
    // Реальный Twilio Verify требует +, чтобы точно знать код страны
    // Временно убираем +
    final String formattedPhone = cleanNumber;

    print('Попытка реальной отправки на: $formattedPhone');

    await Supabase.instance.client.auth.signInWithOtp(
      phone: formattedPhone,
    );

    return true;
  } catch (e) {
    print('Ошибка Supabase Auth (Send): $e');
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
