import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

// 내 정보 (현재 요금제 + 선택 할인) Provider
class UserProfileProvider extends ChangeNotifier {
  final StorageService _storage;
  UserProfile _profile = UserProfile.empty();

  UserProfileProvider(this._storage) {
    _load();
  }

  UserProfile get profile => _profile;

  int get currentPlanAmount => _profile.currentPlanAmount;
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

  Future<void> setPlanAmount(int amount) async {
    _profile = _profile.copyWith(currentPlanAmount: amount);
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
