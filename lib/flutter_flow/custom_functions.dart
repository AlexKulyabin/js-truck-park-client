import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

List<LatLng> parkingsToLatLng(List<ParkingsRow>? parkings) {
  if (parkings == null) {
    return [];
  }

  return parkings
      .where((p) => p.latitude != null && p.longitude != null)
      .map((p) => LatLng(
            p.latitude!,
            p.longitude!,
          ))
      .toList();
}

double getLat(LatLng? position) {
  return position?.latitude ?? 56.9496;
}

double getLng(LatLng? position) {
  return position?.longitude ?? 24.1052;
}

List<LatLng> convertApiToLatLng(List<dynamic>? jsonArray) {
  if (jsonArray == null) return [];

  return jsonArray.map((item) {
    // Достаем координаты, проверяя, что это числа
    final double lat = (item['latitude'] as num).toDouble();
    final double lng = (item['longitude'] as num).toDouble();
    return LatLng(lat, lng);
  }).toList();
}

double calculateRadiusByZoom(double zoom) {
  // Логика: чем меньше зум, тем больше радиус в метрах
  if (zoom < 5) return 2000000; // Весь мир/страна (2000 км)
  if (zoom < 7) return 1000000; // Область (1000 км)
  if (zoom < 9) return 500000; // Несколько городов (500 км)
  if (zoom < 11) return 150000; // Окрестности города (150 км)
  if (zoom < 13) return 50000; // Город (50 км)
  if (zoom < 15) return 20000; // Район (20 км)
  return 5000; // Улица (5 км)
}

int getJsonListLength(List<dynamic> jsonList) {
  // Проверяем, что это действительно список
  if (jsonList is List) {
    return jsonList.length;
  }
  return 0;
}

double calculateRatingPercentage(
  int starCount,
  int s1,
  int s2,
  int s3,
  int s4,
  int s5,
) {
  int total = s1 + s2 + s3 + s4 + s5;
  if (total == 0) return 0.0; // Если отзывов нет, полоска пустая
  return starCount / total;
}

LatLng convertToLatLng(
  double lat,
  double lng,
) {
  return LatLng(lat, lng);
}

bool isWithinAllowedDistance(
  LatLng userLocation,
  LatLng targetLocation,
) {
  // Константа допустимого расстояния в метрах
  const double maxDistance = 500.0;

  // Радиус Земли в метрах
  const double earthRadius = 6371000.0;

  // Переводим градусы в радианы
  double lat1 = userLocation.latitude * math.pi / 180;
  double lon1 = userLocation.longitude * math.pi / 180;
  double lat2 = targetLocation.latitude * math.pi / 180;
  double lon2 = targetLocation.longitude * math.pi / 180;

  // Разница широт и долгот
  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  // Формула Гаверсинуса
  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  double distance = earthRadius * c;

  // Если расстояние меньше или равно 500 метрам, возвращаем true
  return distance <= maxDistance;
}

int enumToScore(String enumString) {
  if (enumString == null) return 3; // Значение по умолчанию

  // Ищем цифру в строке "level5", "level4" и т.д.
  if (enumString.contains('1')) return 1;
  if (enumString.contains('2')) return 2;
  if (enumString.contains('3')) return 3;
  if (enumString.contains('4')) return 4;
  if (enumString.contains('5')) return 5;

  return 3;
}

double getMetersFromIndex(double sliderValue) {
  int index = sliderValue.round();

  switch (index) {
    case 0:
      return 5000.0; // 5 км
    case 1:
      return 10000.0; // 10 км
    case 2:
      return 50000.0; // 50 км
    case 3:
      return 100000.0; // 100 км
    case 4:
      return 150000.0; // 150 км
    default:
      return 5000.0; // Значение по умолчанию
  }
}

String textToLower(String? inputText) {
  if (inputText == null || inputText.isEmpty) {
    return '';
  }
  // Возвращаем текст в нижнем регистре
  return inputText.toLowerCase();
}

String urlEncode(String? text) {
  if (text == null) {
    return '';
  }
  return Uri.encodeComponent(text);
}

double bottomSearchPadding(
  bool isAndroid,
  double safeBottom,
) {
  if (isAndroid) {
    return safeBottom + 16;
  }
  return 41;
}

String getDisplayedMonthlyPrice(SubscriptionPricesStructStruct? prices) {
  if (prices == null) return '4.99 €';
  return prices.isEligible ? prices.referral : prices.monthly;
}

bool isReferralApiSuccess(dynamic jsonBody) {
  if (jsonBody == null) return false;
  try {
    final decoded = jsonBody is String ? jsonDecode(jsonBody) : jsonBody;
    if (decoded is Map && decoded['success'] == true) {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

bool hasUserReviewed(
  List<String>? userIds,
  String? currentUserId,
) {
  if (userIds == null || currentUserId == null || currentUserId.isEmpty) {
    return false;
  }
  // Просто проверяем, есть ли наш ID в списке всех ID авторов
  return userIds.contains(currentUserId);
}
