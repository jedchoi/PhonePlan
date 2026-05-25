// 통신사 요금제/부가서비스 모델

class CarrierPlan {
  final String name;
  final int amount;
  final String category;

  const CarrierPlan({
    required this.name,
    required this.amount,
    required this.category,
  });

  factory CarrierPlan.fromJson(Map<String, dynamic> json) => CarrierPlan(
        name: json['name'] as String,
        amount: json['amount'] as int,
        category: json['category'] as String,
      );
}

class CarrierAddon {
  final String name;
  final int amount;
  final String desc;

  const CarrierAddon({
    required this.name,
    required this.amount,
    required this.desc,
  });

  factory CarrierAddon.fromJson(Map<String, dynamic> json) => CarrierAddon(
        name: json['name'] as String,
        amount: json['amount'] as int,
        desc: json['desc'] as String? ?? '',
      );
}

class Carrier {
  final String id;
  final String name;
  final List<CarrierPlan> plans;
  final List<CarrierAddon> addons;

  const Carrier({
    required this.id,
    required this.name,
    required this.plans,
    required this.addons,
  });

  factory Carrier.fromJson(Map<String, dynamic> json) => Carrier(
        id: json['id'] as String,
        name: json['name'] as String,
        plans: (json['plans'] as List)
            .map((e) => CarrierPlan.fromJson(e as Map<String, dynamic>))
            .toList(),
        addons: (json['addons'] as List)
            .map((e) => CarrierAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
