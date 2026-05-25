// 구매 방식별 계산 결과 모델
enum PurchaseMethod {
  jagup, // 자급제
  seonyak, // 선택약정
  gongsi, // 공시지원
}

extension PurchaseMethodExtension on PurchaseMethod {
  String get label {
    switch (this) {
      case PurchaseMethod.jagup:
        return '자급제';
      case PurchaseMethod.seonyak:
        return '선택약정';
      case PurchaseMethod.gongsi:
        return '공시지원';
    }
  }
}

class PurchaseResult {
  final int devicePrice; // 기기값
  final int planCost; // 요금제 24개월 합계 (할인 적용)
  final int addonCost; // 부가서비스 합계
  final int total; // 총합
  final double appliedRate; // 적용 할인율 (0.0~1.0)
  final String rateExplanation; // 예: "55% (가족결합 30% + 선택약정 25%)"
  final String planDetail; // 요금제 상세 설명

  const PurchaseResult({
    required this.devicePrice,
    required this.planCost,
    required this.addonCost,
    required this.total,
    required this.appliedRate,
    required this.rateExplanation,
    required this.planDetail,
  });
}

class DeviceComparison {
  final PurchaseResult jagup;
  final PurchaseResult seonyak;
  final PurchaseResult gongsi;
  final PurchaseMethod cheapest;

  const DeviceComparison({
    required this.jagup,
    required this.seonyak,
    required this.gongsi,
    required this.cheapest,
  });

  PurchaseResult get cheapestResult {
    switch (cheapest) {
      case PurchaseMethod.jagup:
        return jagup;
      case PurchaseMethod.seonyak:
        return seonyak;
      case PurchaseMethod.gongsi:
        return gongsi;
    }
  }

  PurchaseResult resultFor(PurchaseMethod method) {
    switch (method) {
      case PurchaseMethod.jagup:
        return jagup;
      case PurchaseMethod.seonyak:
        return seonyak;
      case PurchaseMethod.gongsi:
        return gongsi;
    }
  }

  // 특정 방식과 최저가의 차액 (원)
  int diffFrom(PurchaseMethod method) {
    return resultFor(method).total - cheapestResult.total;
  }
}
