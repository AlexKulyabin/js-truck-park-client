import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _places = prefs
              .getStringList('ff_places')
              ?.map(latLngFromString)
              .withoutNulls ??
          _places;
    });
    _safeInit(() {
      _isReadPolicy = prefs.getBool('ff_isReadPolicy') ?? _isReadPolicy;
    });
    _safeInit(() {
      _isOnboarding = prefs.getBool('ff_isOnboarding') ?? _isOnboarding;
    });
    _safeInit(() {
      _tempReferralCode =
          prefs.getString('ff_tempReferralCode') ?? _tempReferralCode;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  List<LatLng> _places = [
    LatLng(55.7539, 37.6208),
    LatLng(55.7486, 37.5385),
    LatLng(55.7282, 37.6015),
    LatLng(55.8263, 37.6376),
    LatLng(55.7093, 37.5422)
  ];
  List<LatLng> get places => _places;
  set places(List<LatLng> value) {
    _places = value;
    prefs.setStringList('ff_places', value.map((x) => x.serialize()).toList());
  }

  void addToPlaces(LatLng value) {
    places.add(value);
    prefs.setStringList(
        'ff_places', _places.map((x) => x.serialize()).toList());
  }

  void removeFromPlaces(LatLng value) {
    places.remove(value);
    prefs.setStringList(
        'ff_places', _places.map((x) => x.serialize()).toList());
  }

  void removeAtIndexFromPlaces(int index) {
    places.removeAt(index);
    prefs.setStringList(
        'ff_places', _places.map((x) => x.serialize()).toList());
  }

  void updatePlacesAtIndex(
    int index,
    LatLng Function(LatLng) updateFn,
  ) {
    places[index] = updateFn(_places[index]);
    prefs.setStringList(
        'ff_places', _places.map((x) => x.serialize()).toList());
  }

  void insertAtIndexInPlaces(int index, LatLng value) {
    places.insert(index, value);
    prefs.setStringList(
        'ff_places', _places.map((x) => x.serialize()).toList());
  }

  bool _isMapUnLocked = true;
  bool get isMapUnLocked => _isMapUnLocked;
  set isMapUnLocked(bool value) {
    _isMapUnLocked = value;
  }

  String _phoneNumber = '';
  String get phoneNumber => _phoneNumber;
  set phoneNumber(String value) {
    _phoneNumber = value;
  }

  String _tempAddress = '';
  String get tempAddress => _tempAddress;
  set tempAddress(String value) {
    _tempAddress = value;
  }

  double _tempLat = 0.0;
  double get tempLat => _tempLat;
  set tempLat(double value) {
    _tempLat = value;
  }

  double _tempLng = 0.0;
  double get tempLng => _tempLng;
  set tempLng(double value) {
    _tempLng = value;
  }

  bool _isFilterShowNearest = false;
  bool get isFilterShowNearest => _isFilterShowNearest;
  set isFilterShowNearest(bool value) {
    _isFilterShowNearest = value;
  }

  int _filterCapacityFrom = 0;
  int get filterCapacityFrom => _filterCapacityFrom;
  set filterCapacityFrom(int value) {
    _filterCapacityFrom = value;
  }

  int _filterCapacityTo = 100;
  int get filterCapacityTo => _filterCapacityTo;
  set filterCapacityTo(int value) {
    _filterCapacityTo = value;
  }

  bool _isFilterHasGas = false;
  bool get isFilterHasGas => _isFilterHasGas;
  set isFilterHasGas(bool value) {
    _isFilterHasGas = value;
  }

  bool _isFilterHasShower = false;
  bool get isFilterHasShower => _isFilterHasShower;
  set isFilterHasShower(bool value) {
    _isFilterHasShower = value;
  }

  bool _isFilterHasLaundry = false;
  bool get isFilterHasLaundry => _isFilterHasLaundry;
  set isFilterHasLaundry(bool value) {
    _isFilterHasLaundry = value;
  }

  bool _isFilterHasHotel = false;
  bool get isFilterHasHotel => _isFilterHasHotel;
  set isFilterHasHotel(bool value) {
    _isFilterHasHotel = value;
  }

  bool _isFilterHasShop = false;
  bool get isFilterHasShop => _isFilterHasShop;
  set isFilterHasShop(bool value) {
    _isFilterHasShop = value;
  }

  bool _isFilterHasRecreation = false;
  bool get isFilterHasRecreation => _isFilterHasRecreation;
  set isFilterHasRecreation(bool value) {
    _isFilterHasRecreation = value;
  }

  double _filterRadius = 0.0;
  double get filterRadius => _filterRadius;
  set filterRadius(double value) {
    _filterRadius = value;
  }

  bool _isFilterApplied = false;
  bool get isFilterApplied => _isFilterApplied;
  set isFilterApplied(bool value) {
    _isFilterApplied = value;
  }

  bool _isDarkThemeOn = false;
  bool get isDarkThemeOn => _isDarkThemeOn;
  set isDarkThemeOn(bool value) {
    _isDarkThemeOn = value;
  }

  bool _isPremium = false;
  bool get isPremium => _isPremium;
  set isPremium(bool value) {
    _isPremium = value;
  }

  bool _isReadPolicy = false;
  bool get isReadPolicy => _isReadPolicy;
  set isReadPolicy(bool value) {
    _isReadPolicy = value;
    prefs.setBool('ff_isReadPolicy', value);
  }

  bool _isOnboarding = false;
  bool get isOnboarding => _isOnboarding;
  set isOnboarding(bool value) {
    _isOnboarding = value;
    prefs.setBool('ff_isOnboarding', value);
  }

  bool _isMonthlyPlan = false;
  bool get isMonthlyPlan => _isMonthlyPlan;
  set isMonthlyPlan(bool value) {
    _isMonthlyPlan = value;
  }

  bool _isYearlyPlan = true;
  bool get isYearlyPlan => _isYearlyPlan;
  set isYearlyPlan(bool value) {
    _isYearlyPlan = value;
  }

  String _deviceId = '';
  String get deviceId => _deviceId;
  set deviceId(String value) {
    _deviceId = value;
  }

  String _tempReferralCode = '';
  String get tempReferralCode => _tempReferralCode;
  set tempReferralCode(String value) {
    _tempReferralCode = value;
    prefs.setString('ff_tempReferralCode', value);
  }

  DateTime? _premiumUntil;
  DateTime? get premiumUntil => _premiumUntil;
  set premiumUntil(DateTime? value) {
    _premiumUntil = value;
  }

  bool _isGuest = false;
  bool get isGuest => _isGuest;
  set isGuest(bool value) {
    _isGuest = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
