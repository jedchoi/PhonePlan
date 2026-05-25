import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/price_preset.dart';
import '../services/storage_service.dart';

// 요금제 프리셋 CRUD Provider
class PricePresetProvider extends ChangeNotifier {
  final StorageService _storage;
  List<PricePreset> _presets = [];

  PricePresetProvider(this._storage) {
    _load();
  }

  List<PricePreset> get presets => List.unmodifiable(_presets);

  void _load() {
    final data = _storage.loadPricePresets();
    _presets = data.map(PricePreset.fromJson).toList();
  }

  Future<void> _save() async {
    await _storage.savePricePresets(_presets.map((p) => p.toJson()).toList());
  }

  Future<void> add({required int amount, String? name}) async {
    _presets.add(PricePreset(id: const Uuid().v4(), name: name, amount: amount));
    await _save();
    notifyListeners();
  }

  Future<void> update(PricePreset updated) async {
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

  /// 통신사 둘러보기에서 요금제 추가
  Future<void> addFromCarrier(String name, int amount) async {
    await add(amount: amount, name: name);
  }

  // 최초 실행 시 기본 요금제 6개 주입
  Future<void> initDefaults() async {
    const uuid = Uuid();
    const defaultAmounts = [59000, 69000, 79000, 89000, 99000, 109000];
    _presets = defaultAmounts
        .map((a) => PricePreset(id: uuid.v4(), amount: a))
        .toList();
    await _save();
    notifyListeners();
  }
}
