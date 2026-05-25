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

  // ─────────────────────────────────────────
  // 기본 기종 목록 (v3 — 19개)
  // ─────────────────────────────────────────
  static final List<Map<String, String>> _defaultPhones = [
    // 삼성 S 시리즈
    {'name': '갤럭시 S25', 'manufacturer': '삼성', 'releaseDate': '2025-02'},
    {'name': '갤럭시 S25+', 'manufacturer': '삼성', 'releaseDate': '2025-02'},
    {'name': '갤럭시 S25 Ultra', 'manufacturer': '삼성', 'releaseDate': '2025-02'},
    {'name': '갤럭시 S25 Edge', 'manufacturer': '삼성', 'releaseDate': '2025-05'},
    // 삼성 Z 시리즈
    {'name': '갤럭시 Z Flip7', 'manufacturer': '삼성', 'releaseDate': '2025-07'},
    {'name': '갤럭시 Z Flip7 FE', 'manufacturer': '삼성', 'releaseDate': '2025-07'},
    {'name': '갤럭시 Z Fold7', 'manufacturer': '삼성', 'releaseDate': '2025-07'},
    // 삼성 A 시리즈
    {'name': '갤럭시 A06', 'manufacturer': '삼성', 'releaseDate': '2025-03'},
    {'name': '갤럭시 A16', 'manufacturer': '삼성', 'releaseDate': '2025-03'},
    {'name': '갤럭시 A26', 'manufacturer': '삼성', 'releaseDate': '2025-03'},
    {'name': '갤럭시 A36', 'manufacturer': '삼성', 'releaseDate': '2025-03'},
    {'name': '갤럭시 A56', 'manufacturer': '삼성', 'releaseDate': '2025-03'},
    // 삼성 기타
    {'name': '갤럭시 퀀텀6', 'manufacturer': '삼성', 'releaseDate': '2025-04'},
    // 애플
    {'name': 'iPhone 16e', 'manufacturer': '애플', 'releaseDate': '2025-02'},
    {'name': 'iPhone 17', 'manufacturer': '애플', 'releaseDate': '2025-09'},
    {'name': 'iPhone 17 Air', 'manufacturer': '애플', 'releaseDate': '2025-09'},
    {'name': 'iPhone 17 Pro', 'manufacturer': '애플', 'releaseDate': '2025-09'},
    {'name': 'iPhone 17 Pro Max', 'manufacturer': '애플', 'releaseDate': '2025-09'},
    {'name': 'iPhone 17e', 'manufacturer': '애플', 'releaseDate': '2026-03'},
  ];

  /// 앱 최초 실행(첫 번째 ever) 시 기본 목록 전체 주입
  Future<void> initDefaults() async {
    if (_presets.isNotEmpty) return;
    await _seedDefaults(_defaultPhones);
  }

  /// 이름 기준 중복 체크 후 누락된 기본 기종만 추가
  /// 반환값: 추가된 기종 수
  Future<int> ensureDefaultPhonesExist() async {
    final existingNames = _presets.map((p) => p.name).toSet();
    final toAdd = _defaultPhones
        .where((d) => !existingNames.contains(d['name']))
        .toList();
    if (toAdd.isEmpty) return 0;
    await _seedDefaults(toAdd);
    return toAdd.length;
  }

  Future<void> _seedDefaults(List<Map<String, String>> phones) async {
    for (final d in phones) {
      _presets.add(PhonePreset(
        id: const Uuid().v4(),
        name: d['name']!,
        manufacturer: d['manufacturer'],
        releaseDate: d['releaseDate'],
      ));
    }
    await _save();
    notifyListeners();
  }
}
