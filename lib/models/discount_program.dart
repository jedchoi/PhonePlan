// 할인프로그램 모델
class DiscountProgram {
  final String id;
  final String name;
  final double rate; // 0.0 ~ 1.0
  final bool isSeonyak; // 선택약정 여부

  const DiscountProgram({
    required this.id,
    required this.name,
    required this.rate,
    required this.isSeonyak,
  });

  DiscountProgram copyWith({
    String? id,
    String? name,
    double? rate,
    bool? isSeonyak,
  }) {
    return DiscountProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      isSeonyak: isSeonyak ?? this.isSeonyak,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rate': rate,
        'isSeonyak': isSeonyak,
      };

  factory DiscountProgram.fromJson(Map<String, dynamic> json) =>
      DiscountProgram(
        id: json['id'] as String,
        name: json['name'] as String,
        rate: (json['rate'] as num).toDouble(),
        isSeonyak: json['isSeonyak'] as bool,
      );
}
