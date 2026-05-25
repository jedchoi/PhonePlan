import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

// 내 정보 (현재 요금제 + 선택 할인 + 통신사) Provider
class UserProfileProvider extends ChangeNotifier {
  final StorageService _storage;
  UserProfile _profile = UserProfile.empty();

  UserProfileProvider(this._storage) {
    _load();
  }

  UserProfile get profile => _profile;

  int get currentPlanAmount => _profile.currentPlanAmount;
  String? get currentPlanName => _profile.currentPlanName;
  String? get currentCarrierId => _profile.currentCarrierId;
  List<String> get selectedDiscountIds => _profile.selectedDiscountIds;

  void _load() {
    final data = _storage.loadUserProfile();
    if (data != null) {
      _profile = UserProfile.fromJson(data);
    }
  }

  Future<void> _save() async {
    await _storage.saveUserProfile(_profile.toJson());
  }

  /// 요금제 금액만 설정 (직접 입력 시) — 이름은 null로 초기화
  Future<void> setPlanAmount(int amount) async {
    _profile = _profile.copyWith(
      currentPlanAmount: amount,
      clearPlanName: true,
    );
    await _save();
    notifyListeners();
  }

  /// 요금제 금액 + 이름 함께 설정 (통신사 요금제 선택 시)
  Future<void> setPlanWithName(int amount, String? planName) async {
    if (planName == null) {
      _profile = _profile.copyWith(
        currentPlanAmount: amount,
        clearPlanName: true,
      );
    } else {
      _profile = _profile.copyWith(
        currentPlanAmount: amount,
        currentPlanName: planName,
      );
    }
    await _save();
    notifyListeners();
  }

  /// 통신사 선택 변경 (UI 필터용, 요금제 금액은 변경하지 않음)
  Future<void> setCarrierId(String? carrierId) async {
    _profile = carrierId == null
        ? _profile.copyWith(clearCarrierId: true)
        : _profile.copyWith(currentCarrierId: carrierId);
    await _save();
    notifyListeners();
  }

  Future<void> toggleDiscount(String id) async {
    final ids = List<String>.from(_profile.selectedDiscountIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    _profile = _profile.copyWith(selectedDiscountIds: ids);
    await _save();
    notifyListeners();
  }

  // 삭제된 할인프로그램 ID를 선택 목록에서 제거
  Future<void> removeDiscountId(String id) async {
    final ids = List<String>.from(_profile.selectedDiscountIds);
    if (ids.remove(id)) {
      _profile = _profile.copyWith(selectedDiscountIds: ids);
      await _save();
      notifyListeners();
    }
  }
}
