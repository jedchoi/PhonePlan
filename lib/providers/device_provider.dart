import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../models/discount_program.dart';
import '../models/purchase_result.dart';
import '../models/user_profile.dart';
import '../services/calculation_service.dart';
import '../services/storage_service.dart';

// 기기 목록 CRUD + 계산 로직 Provider
class DeviceProvider extends ChangeNotifier {
  final StorageService _storage;
  final CalculationService _calculator = CalculationService();
  List<Device> _devices = [];

  DeviceProvider(this._storage) {
    _load();
  }

  List<Device> get devices => List.unmodifiable(_devices);

  void _load() {
    final data = _storage.loadDevices();
    _devices = data.map(Device.fromJson).toList();
  }

  Future<void> _save() async {
    await _storage.saveDevices(_devices.map((d) => d.toJson()).toList());
  }

  Future<void> add(Device device) async {
    final newDevice = device.copyWith(id: const Uuid().v4());
    _devices.add(newDevice);
    await _save();
    notifyListeners();
  }

  Future<void> update(Device updated) async {
    final idx = _devices.indexWhere((d) => d.id == updated.id);
    if (idx == -1) return;
    _devices[idx] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _devices.removeWhere((d) => d.id == id);
    await _save();
    notifyListeners();
  }

  // 특정 기기의 비교 결과 계산
  DeviceComparison compare(
    Device device,
    UserProfile profile,
    List<DiscountProgram> programs,
  ) {
    return _calculator.calculate(device, profile, programs);
  }

  // 모든 기기의 비교 결과 일괄 계산
  Map<String, DeviceComparison> compareAll(
    UserProfile profile,
    List<DiscountProgram> programs,
  ) {
    return {
      for (final device in _devices)
        device.id: _calculator.calculate(device, profile, programs),
    };
  }
}
