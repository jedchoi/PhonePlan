import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/carrier.dart';

// assets/carrier_data.json 로드 서비스
class CarrierDataService {
  static List<Carrier>? _cache;

  /// 통신사 목록 로드 (캐시 사용)
  static Future<List<Carrier>> loadCarriers() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/carrier_data.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['carriers'] as List;
    _cache = list
        .map((e) => Carrier.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
