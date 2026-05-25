// 요금제 프리셋 모델
class PricePreset {
  final String id;
  final String? name; // 선택 입력
  final int amount; // 원 단위

  const PricePreset({
    required this.id,
    this.name,
    required this.amount,
  });

  PricePreset copyWith({
    String? id,
    String? name,
    int? amount,
    bool clearName = false,
  }) {
    return PricePreset(
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

  factory PricePreset.fromJson(Map<String, dynamic> json) => PricePreset(
        id: json['id'] as String,
        name: json['name'] as String?,
        amount: json['amount'] as int,
      );
}
