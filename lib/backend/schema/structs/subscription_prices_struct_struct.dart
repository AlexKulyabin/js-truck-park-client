// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SubscriptionPricesStructStruct extends BaseStruct {
  SubscriptionPricesStructStruct({
    String? monthly,
    String? annual,
    String? referral,
    bool? isEligible,
  })  : _monthly = monthly,
        _annual = annual,
        _referral = referral,
        _isEligible = isEligible;

  // "monthly" field.
  String? _monthly;
  String get monthly => _monthly ?? '';
  set monthly(String? val) => _monthly = val;

  bool hasMonthly() => _monthly != null;

  // "annual" field.
  String? _annual;
  String get annual => _annual ?? '';
  set annual(String? val) => _annual = val;

  bool hasAnnual() => _annual != null;

  // "referral" field.
  String? _referral;
  String get referral => _referral ?? '';
  set referral(String? val) => _referral = val;

  bool hasReferral() => _referral != null;

  // "isEligible" field.
  bool? _isEligible;
  bool get isEligible => _isEligible ?? false;
  set isEligible(bool? val) => _isEligible = val;

  bool hasIsEligible() => _isEligible != null;

  static SubscriptionPricesStructStruct fromMap(Map<String, dynamic> data) =>
      SubscriptionPricesStructStruct(
        monthly: data['monthly'] as String?,
        annual: data['annual'] as String?,
        referral: data['referral'] as String?,
        isEligible: data['isEligible'] as bool?,
      );

  static SubscriptionPricesStructStruct? maybeFromMap(dynamic data) =>
      data is Map
          ? SubscriptionPricesStructStruct.fromMap(data.cast<String, dynamic>())
          : null;

  Map<String, dynamic> toMap() => {
        'monthly': _monthly,
        'annual': _annual,
        'referral': _referral,
        'isEligible': _isEligible,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'monthly': serializeParam(
          _monthly,
          ParamType.String,
        ),
        'annual': serializeParam(
          _annual,
          ParamType.String,
        ),
        'referral': serializeParam(
          _referral,
          ParamType.String,
        ),
        'isEligible': serializeParam(
          _isEligible,
          ParamType.bool,
        ),
      }.withoutNulls;

  static SubscriptionPricesStructStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      SubscriptionPricesStructStruct(
        monthly: deserializeParam(
          data['monthly'],
          ParamType.String,
          false,
        ),
        annual: deserializeParam(
          data['annual'],
          ParamType.String,
          false,
        ),
        referral: deserializeParam(
          data['referral'],
          ParamType.String,
          false,
        ),
        isEligible: deserializeParam(
          data['isEligible'],
          ParamType.bool,
          false,
        ),
      );

  @override
  String toString() => 'SubscriptionPricesStructStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SubscriptionPricesStructStruct &&
        monthly == other.monthly &&
        annual == other.annual &&
        referral == other.referral &&
        isEligible == other.isEligible;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([monthly, annual, referral, isEligible]);
}

SubscriptionPricesStructStruct createSubscriptionPricesStructStruct({
  String? monthly,
  String? annual,
  String? referral,
  bool? isEligible,
}) =>
    SubscriptionPricesStructStruct(
      monthly: monthly,
      annual: annual,
      referral: referral,
      isEligible: isEligible,
    );
