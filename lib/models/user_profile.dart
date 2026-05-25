// 내 정보 모델 (탭1에서 관리)
class UserProfile {
  final int currentPlanAmount; // 현재 요금제 금액
  final String? currentPlanName; // ⭐ v3: 요금제 이름 (통신사 요금제 선택 시)
  final String? currentCarrierId; // ⭐ v3: 선택된 통신사 ID ("skt"/"kt"/"u_plus"/null)
  final List<String> selectedDiscountIds; // 체크된 할인프로그램 id 리스트

  const UserProfile({
    required this.currentPlanAmount,
    this.currentPlanName,
    this.currentCarrierId,
    required this.selectedDiscountIds,
  });

  UserProfile copyWith({
    int? currentPlanAmount,
    String? currentPlanName,
    String? currentCarrierId,
    List<String>? selectedDiscountIds,
    bool clearPlanName = false,
    bool clearCarrierId = false,
  }) {
    return UserProfile(
      currentPlanAmount: currentPlanAmount ?? this.currentPlanAmount,
      currentPlanName: clearPlanName ? null : (currentPlanName ?? this.currentPlanName),
      currentCarrierId: clearCarrierId ? null : (currentCarrierId ?? this.currentCarrierId),
      selectedDiscountIds: selectedDiscountIds ?? this.selectedDiscountIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentPlanAmount': currentPlanAmount,
        'currentPlanName': currentPlanName,
        'currentCarrierId': currentCarrierId,
        'selectedDiscountIds': selectedDiscountIds,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        currentPlanAmount: json['currentPlanAmount'] as int,
        // 기존 데이터에 없으면 null로 처리 (하위 호환)
        currentPlanName: json['currentPlanName'] as String?,
        currentCarrierId: json['currentCarrierId'] as String?,
        selectedDiscountIds:
            List<String>.from(json['selectedDiscountIds'] as List),
      );

  factory UserProfile.empty() => const UserProfile(
        currentPlanAmount: 0,
        selectedDiscountIds: [],
      );
}
