import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences 래퍼 - JSON 직렬화/역직렬화 담당
class StorageService {
  static const String _discountsKey = 'discount_programs';
  static const String _pricePresetsKey = 'price_presets';
  static const String _addonPresetsKey = 'addon_presets';
  static const String _userProfileKey = 'user_profile';
  static const String _devicesKey = 'devices'; // 기존 키 (마이그레이션용)
  static const String _deviceOffersKey = 'device_offers'; // 신규 키
  static const String _phonePresetsKey = 'phone_presets'; // 신규 키
  static const String _initializedKey = 'app_initialized';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  bool get isInitialized => _prefs.getBool(_initializedKey) ?? false;

  Future<void> setInitialized() => _prefs.setBool(_initializedKey, true);

  // --- 할인프로그램 ---
  List<Map<String, dynamic>> loadDiscounts() {
    final jsonStr = _prefs.getString(_discountsKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveDiscounts(List<Map<String, dynamic>> data) =>
      _prefs.setString(_discountsKey, json.encode(data));

  // --- 요금제 프리셋 ---
  List<Map<String, dynamic>> loadPricePresets() {
    final jsonStr = _prefs.getString(_pricePresetsKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> savePricePresets(List<Map<String, dynamic>> data) =>
      _prefs.setString(_pricePresetsKey, json.encode(data));

  // --- 부가서비스 프리셋 ---
  List<Map<String, dynamic>> loadAddonPresets() {
    final jsonStr = _prefs.getString(_addonPresetsKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveAddonPresets(List<Map<String, dynamic>> data) =>
      _prefs.setString(_addonPresetsKey, json.encode(data));

  // --- 내 정보 ---
  Map<String, dynamic>? loadUserProfile() {
    final jsonStr = _prefs.getString(_userProfileKey);
    if (jsonStr == null) return null;
    return json.decode(jsonStr) as Map<String, dynamic>;
  }

  Future<void> saveUserProfile(Map<String, dynamic> data) =>
      _prefs.setString(_userProfileKey, json.encode(data));

  // --- 기기 목록 (구버전 - 마이그레이션용) ---
  List<Map<String, dynamic>> loadOldDevices() {
    final jsonStr = _prefs.getString(_devicesKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> clearOldDevices() => _prefs.remove(_devicesKey);

  // --- 기기 오퍼 목록 (신버전) ---
  List<Map<String, dynamic>> loadDeviceOffers() {
    final jsonStr = _prefs.getString(_deviceOffersKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> saveDeviceOffers(List<Map<String, dynamic>> data) =>
      _prefs.setString(_deviceOffersKey, json.encode(data));

  // --- 기종 프리셋 ---
  List<Map<String, dynamic>> loadPhonePresets() {
    final jsonStr = _prefs.getString(_phonePresetsKey);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> savePhonePresets(List<Map<String, dynamic>> data) =>
      _prefs.setString(_phonePresetsKey, json.encode(data));
}
