import '../models/device.dart';
import '../models/discount_program.dart';
import '../models/purchase_result.dart';
import '../models/user_profile.dart';

// 핵심 비즈니스 로직 - 자급제/선택약정/공시지원 24개월 총지출 계산
class CalculationService {
  static const int totalMonths = 24;

  DeviceComparison calculate(
    Device device,
    UserProfile profile,
    List<DiscountProgram> allPrograms,
  ) {
    // 선택된 할인프로그램만 필터
    final selectedPrograms = allPrograms
        .where((p) => profile.selectedDiscountIds.contains(p.id))
        .toList();

    // 현재 총 할인율 (최대 100%)
    final currentRate =
        selectedPrograms.fold(0.0, (sum, p) => sum + p.rate).clamp(0.0, 1.0);

    // 선택약정 포함 여부
    final hasSeonyak = selectedPrograms.any((p) => p.isSeonyak);

    // 할인 설명 문자열 생성
    String buildRateExplanation(double rate, List<DiscountProgram> programs) {
      if (programs.isEmpty) return '할인 없음';
      final pct = (rate * 100).round();
      final parts = programs.map((p) => '${p.name} ${(p.rate * 100).round()}%').join(' + ');
      return '$pct% ($parts)';
    }

    // ① 자급제 계산
    final jagupResult = _calcJagup(
      device: device,
      profile: profile,
      currentRate: currentRate,
      selectedPrograms: selectedPrograms,
      buildExplanation: buildRateExplanation,
    );

    // ② 선택약정 계산
    final seonyakResult = _calcSeonyak(
      device: device,
      profile: profile,
      currentRate: currentRate,
      hasSeonyak: hasSeonyak,
      selectedPrograms: selectedPrograms,
      buildExplanation: buildRateExplanation,
    );

    // ③ 공시지원 계산
    final gongsiResult = _calcGongsi(
      device: device,
      profile: profile,
      currentRate: currentRate,
      hasSeonyak: hasSeonyak,
      selectedPrograms: selectedPrograms,
      buildExplanation: buildRateExplanation,
    );

    // 가장 저렴한 방식 결정
    final cheapest = _findCheapest(jagupResult, seonyakResult, gongsiResult);

    return DeviceComparison(
      jagup: jagupResult,
      seonyak: seonyakResult,
      gongsi: gongsiResult,
      cheapest: cheapest,
    );
  }

  PurchaseResult _calcJagup({
    required Device device,
    required UserProfile profile,
    required double currentRate,
    required List<DiscountProgram> selectedPrograms,
    required String Function(double, List<DiscountProgram>) buildExplanation,
  }) {
    // 자급제_기기값 + 기존요금제 × 24 × (1 - 현재할인율)
    final planCost =
        (profile.currentPlanAmount * totalMonths * (1 - currentRate)).round();
    final total = device.jagupPrice + planCost;

    return PurchaseResult(
      devicePrice: device.jagupPrice,
      planCost: planCost,
      addonCost: 0,
      total: total,
      appliedRate: currentRate,
      rateExplanation: buildExplanation(currentRate, selectedPrograms),
      planDetail:
          '기존 ${profile.currentPlanAmount}원 × $totalMonths개월 × ${((1 - currentRate) * 100).round()}%',
    );
  }

  PurchaseResult _calcSeonyak({
    required Device device,
    required UserProfile profile,
    required double currentRate,
    required bool hasSeonyak,
    required List<DiscountProgram> selectedPrograms,
    required String Function(double, List<DiscountProgram>) buildExplanation,
  }) {
    // 선택약정 미포함이면 25% 추가
    final double appliedRate = hasSeonyak
        ? currentRate
        : (currentRate + 0.25).clamp(0.0, 1.0);

    final requiredMonths = device.seonyakRequiredMonths.clamp(0, totalMonths);
    final remainMonths = totalMonths - requiredMonths;

    // 필수 요금제 기간 비용
    final requiredPlanCost = requiredMonths > 0
        ? (device.seonyakRequiredPlan * requiredMonths * (1 - appliedRate))
            .round()
        : 0;

    // 나머지 기간 기존 요금제 비용
    final remainPlanCost = remainMonths > 0
        ? (profile.currentPlanAmount * remainMonths * (1 - appliedRate)).round()
        : 0;

    final planCost = requiredPlanCost + remainPlanCost;

    // 부가서비스 비용
    final addonCost =
        device.seonyakAddons.fold(0, (sum, a) => sum + a.amount * a.months);

    final total = device.seonyakPrice + planCost + addonCost;

    // 할인 설명 (선택약정 미포함인 경우 +25% 표시)
    String explanation;
    if (!hasSeonyak) {
      final extra = '선택약정 25%';
      if (selectedPrograms.isEmpty) {
        explanation =
            '${(appliedRate * 100).round()}% ($extra)';
      } else {
        final existingParts = selectedPrograms
            .map((p) => '${p.name} ${(p.rate * 100).round()}%')
            .join(' + ');
        explanation =
            '${(appliedRate * 100).round()}% ($existingParts + $extra)';
      }
    } else {
      explanation = buildExplanation(appliedRate, selectedPrograms);
    }

    String planDetail = '';
    if (requiredMonths > 0) {
      planDetail =
          '필수요금제 ${device.seonyakRequiredPlan}원 × $requiredMonths개월 × ${((1 - appliedRate) * 100).round()}%';
    }
    if (remainMonths > 0) {
      if (planDetail.isNotEmpty) planDetail += '\n';
      planDetail +=
          '기존 ${profile.currentPlanAmount}원 × $remainMonths개월 × ${((1 - appliedRate) * 100).round()}%';
    }

    return PurchaseResult(
      devicePrice: device.seonyakPrice,
      planCost: planCost,
      addonCost: addonCost,
      total: total,
      appliedRate: appliedRate,
      rateExplanation: explanation,
      planDetail: planDetail,
    );
  }

  PurchaseResult _calcGongsi({
    required Device device,
    required UserProfile profile,
    required double currentRate,
    required bool hasSeonyak,
    required List<DiscountProgram> selectedPrograms,
    required String Function(double, List<DiscountProgram>) buildExplanation,
  }) {
    // 선택약정 포함이면 25% 차감 (최소 0)
    final double appliedRate = hasSeonyak
        ? (currentRate - 0.25).clamp(0.0, 1.0)
        : currentRate;

    final requiredMonths = device.gongsiRequiredMonths.clamp(0, totalMonths);
    final remainMonths = totalMonths - requiredMonths;

    // 필수 요금제 기간 비용
    final requiredPlanCost = requiredMonths > 0
        ? (device.gongsiRequiredPlan * requiredMonths * (1 - appliedRate))
            .round()
        : 0;

    // 나머지 기간 기존 요금제 비용
    final remainPlanCost = remainMonths > 0
        ? (profile.currentPlanAmount * remainMonths * (1 - appliedRate)).round()
        : 0;

    final planCost = requiredPlanCost + remainPlanCost;

    // 부가서비스 비용
    final addonCost =
        device.gongsiAddons.fold(0, (sum, a) => sum + a.amount * a.months);

    final total = device.gongsiPrice + planCost + addonCost;

    // 할인 설명 (선택약정 포함인 경우 -25% 표시)
    String explanation;
    if (hasSeonyak) {
      final seonyakPrograms =
          selectedPrograms.where((p) => p.isSeonyak).toList();
      final nonSeonyakPrograms =
          selectedPrograms.where((p) => !p.isSeonyak).toList();
      if (nonSeonyakPrograms.isEmpty && seonyakPrograms.isNotEmpty) {
        explanation =
            '${(appliedRate * 100).round()}% (선택약정 사용 불가로 0%)';
      } else {
        explanation = buildExplanation(appliedRate, nonSeonyakPrograms);
      }
    } else {
      explanation = buildExplanation(appliedRate, selectedPrograms);
    }

    String planDetail = '';
    if (requiredMonths > 0) {
      planDetail =
          '필수요금제 ${device.gongsiRequiredPlan}원 × $requiredMonths개월 × ${((1 - appliedRate) * 100).round()}%';
    }
    if (remainMonths > 0) {
      if (planDetail.isNotEmpty) planDetail += '\n';
      planDetail +=
          '기존 ${profile.currentPlanAmount}원 × $remainMonths개월 × ${((1 - appliedRate) * 100).round()}%';
    }

    return PurchaseResult(
      devicePrice: device.gongsiPrice,
      planCost: planCost,
      addonCost: addonCost,
      total: total,
      appliedRate: appliedRate,
      rateExplanation: explanation,
      planDetail: planDetail,
    );
  }

  PurchaseMethod _findCheapest(
    PurchaseResult jagup,
    PurchaseResult seonyak,
    PurchaseResult gongsi,
  ) {
    final minTotal =
        [jagup.total, seonyak.total, gongsi.total].reduce((a, b) => a < b ? a : b);
    if (jagup.total == minTotal) return PurchaseMethod.jagup;
    if (seonyak.total == minTotal) return PurchaseMethod.seonyak;
    return PurchaseMethod.gongsi;
  }
}
