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
import 'package:purchases_flutter/purchases_flutter.dart';

Future<bool> purchaseSmartPackage(
  String packageType,
  bool applyDiscount,
) async {
  try {
    // 1. Получаем текущие предложения
    Offerings offerings = await Purchases.getOfferings();
    if (offerings.current == null) return false;

    // 2. Выбираем нужный пакет
    Package? package;
    if (packageType == 'monthly') {
      package = offerings.current!.monthly;
    } else if (packageType == 'annual') {
      package = offerings.current!.annual;
    }

    if (package == null) return false;

    // 3. ЛОГИКА ПОКУПКИ
    if (Platform.isIOS) {
      // --- iOS (Apple) ---
      if (applyDiscount && packageType == 'monthly') {
        // Покупка со скидкой 3.99
        final discounts = package.storeProduct.discounts;
        if (discounts != null && discounts.isNotEmpty) {
          final discount = discounts.firstWhere(
            (d) => d.identifier == 'monthly_referral_399',
            orElse: () => discounts.first,
          );
          final promoOffer = await Purchases.getPromotionalOffer(
              package.storeProduct, discount);
          await Purchases.purchaseDiscountedPackage(package, promoOffer);
        } else {
          await Purchases.purchasePackage(package);
        }
      } else {
        // Стандартная покупка для iOS
        await Purchases.purchasePackage(package);
      }
    } else {
      // --- Android (Google) ---
      final subscriptionOptions = package.storeProduct.subscriptionOptions;

      if (subscriptionOptions != null && subscriptionOptions.isNotEmpty) {
        SubscriptionOption? optionToPurchase;

        if (applyDiscount && packageType == 'monthly') {
          // Ищем реферальную скидку 3.99
          try {
            optionToPurchase = subscriptionOptions.firstWhere(
              (opt) =>
                  opt.id.replaceAll('_', '-').contains('monthly-referral-399'),
            );
          } catch (e) {
            optionToPurchase = package.storeProduct.defaultOption;
          }
        } else {
          // Берем стандартный базовый план (4.99 или 49.99)
          optionToPurchase = package.storeProduct.defaultOption;
        }

        if (optionToPurchase != null) {
          await Purchases.purchaseSubscriptionOption(optionToPurchase);
        } else {
          // Резервный метод, если опции не найдены
          await Purchases.purchasePackage(package);
        }
      } else {
        await Purchases.purchasePackage(package);
      }
    }

    // 4. ПРОВЕРКА РЕЗУЛЬТАТА
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    bool isSuccess =
        customerInfo.entitlements.all['premium']?.isActive ?? false;

    // Если покупка успешна и это был реферал, можно здесь же пометить в базе,
    // что скидка использована (referred_by_id мы не трогаем, просто фиксируем успех)
    return isSuccess;
  } catch (e) {
    print("Ошибка покупки: $e");
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
