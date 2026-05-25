// 비교할 기기 모델
class RequiredAddon {
  final int amount; // 월 요금
  final int months; // 의무 개월수
  final String? presetId; // 어떤 부가서비스 프리셋에서 왔는지

  const RequiredAddon({
    required this.amount,
    required this.months,
    this.presetId,
  });

  RequiredAddon copyWith({
    int? amount,
    int? months,
    String? presetId,
    bool clearPresetId = false,
  }) {
    return RequiredAddon(
      amount: amount ?? this.amount,
      months: months ?? this.months,
      presetId: clearPresetId ? null : (presetId ?? this.presetId),
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'months': months,
        'presetId': presetId,
      };

  factory RequiredAddon.fromJson(Map<String, dynamic> json) => RequiredAddon(
        amount: json['amount'] as int,
        months: json['months'] as int,
        presetId: json['presetId'] as String?,
      );
}

class Device {
  final String id;
  final String name; // 기기명

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

  const Device({
    required this.id,
    required this.name,
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

  Device copyWith({
    String? id,
    String? name,
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
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
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
        'name': name,
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

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
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
