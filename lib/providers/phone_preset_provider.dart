import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/phone_preset.dart';
import '../services/storage_service.dart';

// 기종 프리셋 CRUD Provider
class PhonePresetProvider extends ChangeNotifier {
  final StorageService _storage;
  List<PhonePreset> _presets = [];

  PhonePresetProvider(this._storage) {
    _load();
  }

  List<PhonePreset> get presets => List.unmodifiable(_presets);

  void _load() {
    final data = _storage.loadPhonePresets();
    _presets = data.map(PhonePreset.fromJson).toList();
  }

  Future<void> _save() async {
    await _storage.savePhonePresets(_presets.map((p) => p.toJson()).toList());
  }

  PhonePreset? getById(String id) {
    try {
      return _presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPreset(PhonePreset preset) async {
    final newPreset = preset.copyWith(id: const Uuid().v4());
    _presets.add(newPreset);
    await _save();
    notifyListeners();
  }

  // 마이그레이션용: id 그대로 직접 추가
  Future<void> addPresetDirect(PhonePreset preset) async {
    _presets.add(preset);
    await _save();
    notifyListeners();
  }

  Future<void> updatePreset(PhonePreset updated) async {
    final idx = _presets.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    _presets[idx] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> removePreset(String id) async {
    _presets.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  /// 기종별 자급제 기본가 자동 학습
  Future<void> updateDefaultJagupPrice(String id, int price) async {
    final idx = _presets.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _presets[idx] = _presets[idx].copyWith(defaultJagupPrice: price);
    await _save();
    notifyListeners();
  }

  /// 앱 최초 실행 시 기본 13개 기종 초기화
  Future<void> initDefaults() async {
    if (_presets.isNotEmpty) return;

    final defaults = [
      // 삼성
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 S25', manufacturer: '삼성', releaseDate: '2025-02'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 S25+', manufacturer: '삼성', releaseDate: '2025-02'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 S25 Ultra', manufacturer: '삼성', releaseDate: '2025-02'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 S25 Edge', manufacturer: '삼성', releaseDate: '2025-05'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 Z Flip7', manufacturer: '삼성', releaseDate: '2025-07'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 Z Fold7', manufacturer: '삼성', releaseDate: '2025-07'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 A36', manufacturer: '삼성', releaseDate: '2025-03'),
      PhonePreset(id: const Uuid().v4(), name: '갤럭시 A56', manufacturer: '삼성', releaseDate: '2025-03'),
      // 애플
      PhonePreset(id: const Uuid().v4(), name: 'iPhone 16e', manufacturer: '애플', releaseDate: '2025-02'),
      PhonePreset(id: const Uuid().v4(), name: 'iPhone 17', manufacturer: '애플', releaseDate: '2025-09'),
      PhonePreset(id: const Uuid().v4(), name: 'iPhone 17 Plus', manufacturer: '애플', releaseDate: '2025-09'),
      PhonePreset(id: const Uuid().v4(), name: 'iPhone 17 Pro', manufacturer: '애플', releaseDate: '2025-09'),
      PhonePreset(id: const Uuid().v4(), name: 'iPhone 17 Pro Max', manufacturer: '애플', releaseDate: '2025-09'),
    ];

    _presets = defaults;
    await _save();
    notifyListeners();
  }
}
