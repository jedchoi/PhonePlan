import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/device_offer.dart';
import '../models/discount_program.dart';
import '../models/purchase_result.dart';
import '../models/user_profile.dart';
import '../services/calculation_service.dart';
import '../services/storage_service.dart';
import 'phone_preset_provider.dart';

// 기기 오퍼 목록 CRUD + 계산 로직 Provider
class DeviceProvider extends ChangeNotifier {
  final StorageService _storage;
  final CalculationService _calculator = CalculationService();
  List<DeviceOffer> _offers = [];

  DeviceProvider(this._storage) {
    _load();
  }

  List<DeviceOffer> get offers => List.unmodifiable(_offers);

  void _load() {
    final data = _storage.loadDeviceOffers();
    _offers = data.map(DeviceOffer.fromJson).toList();
  }

  Future<void> _save() async {
    await _storage.saveDeviceOffers(_offers.map((o) => o.toJson()).toList());
  }

  /// 오퍼 추가 (자동학습 포함)
  Future<void> addOffer(
    DeviceOffer offer,
    PhonePresetProvider phoneProvider,
  ) async {
    final newOffer = offer.copyWith(id: const Uuid().v4());
    _offers.add(newOffer);
    await _save();

    // 기종별 자급제 기본가 자동 학습
    final preset = phoneProvider.getById(newOffer.phonePresetId);
    if (preset != null &&
        preset.defaultJagupPrice == null &&
        newOffer.jagupPrice > 0) {
      await phoneProvider.updateDefaultJagupPrice(
          preset.id, newOffer.jagupPrice);
    }

    notifyListeners();
  }

  /// 마이그레이션용: 자동학습 없이 직접 추가
  Future<void> addOfferDirect(DeviceOffer offer) async {
    _offers.add(offer);
    await _save();
    notifyListeners();
  }

  /// 오퍼 수정 (자동학습 포함)
  Future<void> updateOffer(
    DeviceOffer updated,
    PhonePresetProvider phoneProvider,
  ) async {
    final idx = _offers.indexWhere((o) => o.id == updated.id);
    if (idx == -1) return;
    _offers[idx] = updated;
    await _save();

    // 기종별 자급제 기본가 자동 학습
    final preset = phoneProvider.getById(updated.phonePresetId);
    if (preset != null &&
        preset.defaultJagupPrice == null &&
        updated.jagupPrice > 0) {
      await phoneProvider.updateDefaultJagupPrice(
          preset.id, updated.jagupPrice);
    }

    notifyListeners();
  }

  Future<void> removeOffer(String id) async {
    _offers.removeWhere((o) => o.id == id);
    await _save();
    notifyListeners();
  }

  // 특정 오퍼의 비교 결과 계산
  DeviceComparison compare(
    DeviceOffer offer,
    UserProfile profile,
    List<DiscountProgram> programs,
  ) {
    return _calculator.calculate(offer, profile, programs);
  }

  // 모든 오퍼의 비교 결과 일괄 계산
  Map<String, DeviceComparison> compareAll(
    UserProfile profile,
    List<DiscountProgram> programs,
  ) {
    return {
      for (final offer in _offers)
        offer.id: _calculator.calculate(offer, profile, programs),
    };
  }
}
