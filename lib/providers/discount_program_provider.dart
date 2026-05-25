import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/discount_program.dart';
import '../services/storage_service.dart';

// 할인프로그램 마스터 CRUD Provider
class DiscountProgramProvider extends ChangeNotifier {
  final StorageService _storage;
  List<DiscountProgram> _programs = [];

  DiscountProgramProvider(this._storage) {
    _load();
  }

  List<DiscountProgram> get programs => List.unmodifiable(_programs);

  void _load() {
    final data = _storage.loadDiscounts();
    _programs = data.map(DiscountProgram.fromJson).toList();
  }

  Future<void> _save() async {
    await _storage.saveDiscounts(_programs.map((p) => p.toJson()).toList());
  }

  Future<void> add({
    required String name,
    required double rate,
    required bool isSeonyak,
  }) async {
    _programs.add(DiscountProgram(
      id: const Uuid().v4(),
      name: name,
      rate: rate,
      isSeonyak: isSeonyak,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> update(DiscountProgram updated) async {
    final idx = _programs.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    _programs[idx] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _programs.removeWhere((p) => p.id == id);
    await _save();
    notifyListeners();
  }

  // 최초 실행 시 기본 할인프로그램 3개 주입
  Future<void> initDefaults() async {
    const uuid = Uuid();
    _programs = [
      DiscountProgram(id: uuid.v4(), name: '가족결합', rate: 0.30, isSeonyak: false),
      DiscountProgram(id: uuid.v4(), name: '복지할인', rate: 0.35, isSeonyak: false),
      DiscountProgram(id: uuid.v4(), name: '선택약정', rate: 0.25, isSeonyak: true),
    ];
    await _save();
    notifyListeners();
  }
}
