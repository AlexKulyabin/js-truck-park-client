import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/core/config/app_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class GetParkingsByViewportCall {
  static Future<ApiCallResponse> call({
    double? minLat,
    double? minLng,
    double? maxLat,
    double? maxLng,
    double? zoom,
  }) async {
    final config = AppConfig.current;
    final ffApiRequestBody = '''
{
  "min_lng": ${minLng},
  "min_lat": ${minLat},
  "max_lng": ${maxLng},
  "max_lat": ${maxLat},
  "zoom_level": ${zoom}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetParkingsByViewport',
      apiUrl: config.supabaseRpcUrl('get_parkings_by_viewport'),
      callType: ApiCallType.POST,
      headers: {
        ...config.anonymousSupabaseHeaders,
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<double>? lat(dynamic response) => (getJsonField(
        response,
        r'''$[:].lat''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<double>(x))
          .withoutNulls
          .toList();
  static List<double>? lng(dynamic response) => (getJsonField(
        response,
        r'''$[:].lng''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<double>(x))
          .withoutNulls
          .toList();
  static List<int>? count(dynamic response) => (getJsonField(
        response,
        r'''$[:].count''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
  static List<String>? id(dynamic response) => (getJsonField(
        response,
        r'''$[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<bool>? iscluster(dynamic response) => (getJsonField(
        response,
        r'''$[:].is_cluster''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<bool>(x))
          .withoutNulls
          .toList();
}

class GetAddressFromCoordsCall {
  static Future<ApiCallResponse> call({
    double? lat,
    double? lng,
    String? key = 'AIzaSyBjnlSOctaIJus2EfVMcVkZ--eEWbiN58Q',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetAddressFromCoords',
      apiUrl:
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&key=AIzaSyBjnlSOctaIJus2EfVMcVkZ--eEWbiN58Q&language=en',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetFilteredParkingsCall {
  static Future<ApiCallResponse> call({
    double? lat,
    double? lng,
    double? radius,
    int? minCap,
    int? maxCap,
    bool? gas,
    bool? shower,
    bool? laundry,
    bool? hotel,
    bool? shop,
    bool? recreation,
    bool? isActive,
    double? minLat,
    double? maxLat,
    double? minLng,
    double? maxLng,
    double? zoom,
    String? searchQuery = '',
  }) async {
    final config = AppConfig.current;
    final ffApiRequestBody = '''
{
  "center_lat": ${lat},
  "center_lng": ${lng},
  "radius_meters": ${radius},
  "min_capacity": ${minCap},
  "max_capacity": ${maxCap},
  "min_lat": ${minLat},
  "max_lat": ${maxLat},
  "min_lng": ${minLng},
  "max_lng": ${maxLng},
  "need_gas": ${gas},
  "need_shower": ${shower},
  "need_laundry": ${laundry},
  "need_hotel": ${hotel},
  "need_shop": ${shop},
  "need_recreation": ${recreation},
  "zoom_level": ${zoom},
  "search_query": "${escapeStringForJson(searchQuery)}",
  "is_filter_active": ${isActive}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GetFilteredParkings',
      apiUrl: config.supabaseRpcUrl('get_filtered_parkings'),
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        ...config.anonymousSupabaseHeaders,
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class DeleteUserAccountCall {
  static Future<ApiCallResponse> call({
    String? userToken = '',
  }) async {
    final config = AppConfig.current;
    final ffApiRequestBody = '''
{
  "confirm": true
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'DeleteUserAccount',
      apiUrl: config.supabaseRpcUrl('delete_user_account'),
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey': config.supabasePublishableKey,
        'Authorization': 'Bearer ${userToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ProcessReferralCall {
  static Future<ApiCallResponse> call({
    String? refCode = '',
    String? refereeId = '',
    String? deviceId = '',
    String? userToken = '',
  }) async {
    final config = AppConfig.current;
    final ffApiRequestBody = '''
{
  "p_ref_code": "${escapeStringForJson(refCode)}",
  "p_referee_id": "${escapeStringForJson(refereeId)}",
  "p_device_id": "${escapeStringForJson(deviceId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ProcessReferral',
      apiUrl: config.supabaseRpcUrl('process_referral'),
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey': config.supabasePublishableKey,
        'Authorization': 'Bearer ${userToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
