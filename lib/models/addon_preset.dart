// 부가서비스 프리셋 모델
class AddonPreset {
  final String id;
  final String? name; // 선택 입력
  final int amount; // 월 요금 (원)

  const AddonPreset({
    required this.id,
    this.name,
    required this.amount,
  });

  AddonPreset copyWith({
    String? id,
    String? name,
    int? amount,
    bool clearName = false,
  }) {
    return AddonPreset(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
      };

  factory AddonPreset.fromJson(Map<String, dynamic> json) => AddonPreset(
        id: json['id'] as String,
        name: json['name'] as String?,
        amount: json['amount'] as int,
      );
}
