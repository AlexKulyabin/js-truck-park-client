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

Future<SubscriptionPricesStructStruct> getSmartSubscriptionPrices() async {
  // Дефолтные значения на случай сбоя
  String monthly = "4.99 €";
  String annual = "49.99 €";
  String referral = "3.99 €";
  bool isEligible = false;

  final String? userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    return createSubscriptionPricesStructStruct(
      monthly: monthly,
      annual: annual,
      referral: referral,
      isEligible: isEligible,
    );
  }

  try {
    // 1. ПРОВЕРКА РЕФЕРАЛА В SUPABASE
    final userResponse = await Supabase.instance.client
        .from('users')
        .select('referred_by_id')
        .eq('id', userId)
        .maybeSingle();

    isEligible = userResponse != null && userResponse['referred_by_id'] != null;

    // 2. ПОЛУЧЕНИЕ ЦЕН ИЗ REVENUECAT
    Offerings offerings = await Purchases.getOfferings();

    if (offerings.current != null) {
      final monthlyPkg = offerings.current!.monthly;
      final annualPkg = offerings.current!.annual;

      if (monthlyPkg != null) {
        monthly = monthlyPkg.storeProduct.priceString;

        if (isEligible) {
          if (Platform.isIOS) {
            final discounts = monthlyPkg.storeProduct.discounts;
            if (discounts != null && discounts.isNotEmpty) {
              try {
                final refOffer = discounts.firstWhere(
                  (d) => d.identifier == 'monthly_referral_399',
                );
                referral = refOffer.priceString;
              } catch (e) {
                referral = discounts.first.priceString;
              }
            }
          } else {
            final subscriptionOptions =
                monthlyPkg.storeProduct.subscriptionOptions;

            if (subscriptionOptions != null && subscriptionOptions.isNotEmpty) {
              SubscriptionOption? refOption;
              try {
                refOption = subscriptionOptions.firstWhere(
                  (opt) => opt.id
                      .replaceAll('_', '-')
                      .contains('monthly-referral-399'),
                );
              } catch (e) {
                refOption = null;
              }

              if (refOption != null && refOption.pricingPhases.isNotEmpty) {
                referral = refOption.pricingPhases.first.price.formatted;
              }
            }
          }
        }
      }

      if (annualPkg != null) {
        annual = annualPkg.storeProduct.priceString;
      }
    }
  } catch (e) {
    print("RevenueCat Smart Prices Error: $e");
  }

  return createSubscriptionPricesStructStruct(
    monthly: monthly,
    annual: annual,
    referral: referral,
    isEligible: isEligible,
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
