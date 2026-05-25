import 'device.dart';

// 매장별 기기 구매 조건 모델 (Device를 대체)
class DeviceOffer {
  final String id;
  final String phonePresetId; // PhonePreset.id 참조
  final String storeName; // 매장명 (예: 강남 A매장, 쿠팡, 공식몰)

  // 자급제
  final int jagupPrice; // 기기 현금가

  // 선택약정
  final int seonyakPrice; // 기기 현금가
  final int seonyakRequiredPlan; // 필수 요금제 금액
  final int seonyakRequiredMonths; // 필수 요금제 유지 개월수
  final List<RequiredAddon> seonyakAddons; // 필수 부가서비스 리스트

  // 공시지원
  final int gongsiPrice; // 기기 현금가(공시지원금 차감 후)
  final int gongsiRequiredPlan; // 필수 요금제 금액
  final int gongsiRequiredMonths; // 필수 요금제 유지 개월수
  final List<RequiredAddon> gongsiAddons; // 필수 부가서비스 리스트

  const DeviceOffer({
    required this.id,
    required this.phonePresetId,
    required this.storeName,
    required this.jagupPrice,
    required this.seonyakPrice,
    required this.seonyakRequiredPlan,
    required this.seonyakRequiredMonths,
    required this.seonyakAddons,
    required this.gongsiPrice,
    required this.gongsiRequiredPlan,
    required this.gongsiRequiredMonths,
    required this.gongsiAddons,
  });

  DeviceOffer copyWith({
    String? id,
    String? phonePresetId,
    String? storeName,
    int? jagupPrice,
    int? seonyakPrice,
    int? seonyakRequiredPlan,
    int? seonyakRequiredMonths,
    List<RequiredAddon>? seonyakAddons,
    int? gongsiPrice,
    int? gongsiRequiredPlan,
    int? gongsiRequiredMonths,
    List<RequiredAddon>? gongsiAddons,
  }) {
    return DeviceOffer(
      id: id ?? this.id,
      phonePresetId: phonePresetId ?? this.phonePresetId,
      storeName: storeName ?? this.storeName,
      jagupPrice: jagupPrice ?? this.jagupPrice,
      seonyakPrice: seonyakPrice ?? this.seonyakPrice,
      seonyakRequiredPlan: seonyakRequiredPlan ?? this.seonyakRequiredPlan,
      seonyakRequiredMonths:
          seonyakRequiredMonths ?? this.seonyakRequiredMonths,
      seonyakAddons: seonyakAddons ?? this.seonyakAddons,
      gongsiPrice: gongsiPrice ?? this.gongsiPrice,
      gongsiRequiredPlan: gongsiRequiredPlan ?? this.gongsiRequiredPlan,
      gongsiRequiredMonths:
          gongsiRequiredMonths ?? this.gongsiRequiredMonths,
      gongsiAddons: gongsiAddons ?? this.gongsiAddons,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phonePresetId': phonePresetId,
        'storeName': storeName,
        'jagupPrice': jagupPrice,
        'seonyakPrice': seonyakPrice,
        'seonyakRequiredPlan': seonyakRequiredPlan,
        'seonyakRequiredMonths': seonyakRequiredMonths,
        'seonyakAddons': seonyakAddons.map((a) => a.toJson()).toList(),
        'gongsiPrice': gongsiPrice,
        'gongsiRequiredPlan': gongsiRequiredPlan,
        'gongsiRequiredMonths': gongsiRequiredMonths,
        'gongsiAddons': gongsiAddons.map((a) => a.toJson()).toList(),
      };

  factory DeviceOffer.fromJson(Map<String, dynamic> json) => DeviceOffer(
        id: json['id'] as String,
        phonePresetId: json['phonePresetId'] as String,
        storeName: json['storeName'] as String? ?? '기본 매장',
        jagupPrice: json['jagupPrice'] as int,
        seonyakPrice: json['seonyakPrice'] as int,
        seonyakRequiredPlan: json['seonyakRequiredPlan'] as int,
        seonyakRequiredMonths: json['seonyakRequiredMonths'] as int,
        seonyakAddons: (json['seonyakAddons'] as List)
            .map((e) => RequiredAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
        gongsiPrice: json['gongsiPrice'] as int,
        gongsiRequiredPlan: json['gongsiRequiredPlan'] as int,
        gongsiRequiredMonths: json['gongsiRequiredMonths'] as int,
        gongsiAddons: (json['gongsiAddons'] as List)
            .map((e) => RequiredAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
