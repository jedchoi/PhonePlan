import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/addon_preset.dart';
import '../services/storage_service.dart';

// 부가서비스 프리셋 CRUD Provider
class AddonPresetProvider extends ChangeNotifier {
  final StorageService _storage;
  List<AddonPreset> _presets = [];

  AddonPresetProvider(this._storage) {
    _load();
  }

  List<AddonPreset> get presets => List.unmodifiable(_presets);

  void _load() {
    final data = _storage.loadAddonPresets();
    _presets = data.map(AddonPreset.fromJson).toList();
  }

  Future<void> _save() async {
    await _storage.saveAddonPresets(_presets.map((p) => p.toJson()).toList());
  }

  Future<void> add({required int amount, String? name}) async {
    _presets.add(AddonPreset(id: const Uuid().v4(), name: name, amount: amount));
    await _save();
    notifyListeners();
  }

  Future<void> update(AddonPreset updated) async {
    final idx = _presets.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    _presets[idx] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _presets.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  // 최초 실행 시 기본 부가서비스 6개 주입
  Future<void> initDefaults() async {
    const uuid = Uuid();
    _presets = [
      AddonPreset(id: uuid.v4(), name: '넷플릭스 베이직', amount: 5500),
      AddonPreset(id: uuid.v4(), name: '디즈니플러스', amount: 9900),
      AddonPreset(id: uuid.v4(), name: '멜론 스트리밍', amount: 7900),
      AddonPreset(id: uuid.v4(), name: 'T 안심클럽', amount: 3300),
      AddonPreset(id: uuid.v4(), name: '컬러링', amount: 990),
      AddonPreset(id: uuid.v4(), name: '보험 (스마트케어)', amount: 5900),
    ];
    await _save();
    notifyListeners();
  }
}
