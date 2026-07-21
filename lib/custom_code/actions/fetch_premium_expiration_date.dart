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

// ... (оставляем те, что FF добавит сам)

import 'package:purchases_flutter/purchases_flutter.dart';

Future<DateTime?> fetchPremiumExpirationDate() async {
  try {
    // Получаем свежие данные о пользователе из RevenueCat
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    // Берем наше право доступа "premium"
    EntitlementInfo? entitlement = customerInfo.entitlements.all['premium'];

    if (entitlement != null && entitlement.isActive) {
      if (entitlement.expirationDate != null) {
        return DateTime.parse(entitlement.expirationDate!);
      }
      // Если подписка вечная (Lifetime)
      return DateTime(2099, 12, 31);
    }
  } catch (e) {
    print("Ошибка биллинга: $e");
  }
  return null;
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
