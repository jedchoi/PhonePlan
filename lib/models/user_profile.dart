// 내 정보 모델 (탭1에서 관리)
class UserProfile {
  final int currentPlanAmount; // 현재 요금제 금액
  final List<String> selectedDiscountIds; // 체크된 할인프로그램 id 리스트

  const UserProfile({
    required this.currentPlanAmount,
    required this.selectedDiscountIds,
  });

  UserProfile copyWith({
    int? currentPlanAmount,
    List<String>? selectedDiscountIds,
  }) {
    return UserProfile(
      currentPlanAmount: currentPlanAmount ?? this.currentPlanAmount,
      selectedDiscountIds: selectedDiscountIds ?? this.selectedDiscountIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentPlanAmount': currentPlanAmount,
        'selectedDiscountIds': selectedDiscountIds,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        currentPlanAmount: json['currentPlanAmount'] as int,
        selectedDiscountIds:
            List<String>.from(json['selectedDiscountIds'] as List),
      );

  factory UserProfile.empty() => const UserProfile(
        currentPlanAmount: 0,
        selectedDiscountIds: [],
      );
}
