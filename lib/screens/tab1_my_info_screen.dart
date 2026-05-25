import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/discount_program_provider.dart';
import '../providers/price_preset_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/price_chip_selector.dart';

// 탭1: 내 정보 화면 (현재 요금제 + 할인프로그램 선택)
class Tab1MyInfoScreen extends StatelessWidget {
  const Tab1MyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: Consumer3<UserProfileProvider, PricePresetProvider,
          DiscountProgramProvider>(
        builder: (context, profileProv, priceProv, discountProv, _) {
          final profile = profileProv.profile;
          final selectedIds = profile.selectedDiscountIds;
          final programs = discountProv.programs;
          final fmt = NumberFormat('#,###', 'ko_KR');

          // 현재 할인율 계산
          double totalRate = 0;
          bool hasSeonyak = false;
          final selectedNames = <String>[];
          for (final p in programs) {
            if (selectedIds.contains(p.id)) {
              totalRate += p.rate;
              if (p.isSeonyak) hasSeonyak = true;
              selectedNames.add('${p.name} ${(p.rate * 100).round()}%');
            }
          }
          final clampedRate = totalRate.clamp(0.0, 1.0);
          final isCapped = totalRate > 1.0;
          final ratePct = (clampedRate * 100).round();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // --- 현재 요금제 섹션 ---
              const Text(
                '현재 사용 중인 요금제',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              PriceChipSelector(
                presets: priceProv.presets,
                selectedAmount: profile.currentPlanAmount > 0
                    ? profile.currentPlanAmount
                    : null,
                onSelected: (amount) => profileProv.setPlanAmount(amount),
              ),
              if (profile.currentPlanAmount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '선택된 요금제: ${fmt.format(profile.currentPlanAmount)}원/월',
                  style: const TextStyle(
                      color: AppTheme.primary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- 할인프로그램 섹션 ---
              const Text(
                '현재 적용 중인 할인프로그램',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (programs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '설정 탭에서 할인프로그램을 추가해주세요.',
                    style: TextStyle(color: AppTheme.diffColor),
                  ),
                )
              else
                ...programs.map((program) {
                  final isSelected = selectedIds.contains(program.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) =>
                          profileProv.toggleDiscount(program.id),
                      title: Row(
                        children: [
                          Text(
                            program.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(program.rate * 100).round()}%',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          if (program.isSeonyak) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.seonyakBadge.withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppTheme.seonyakBadge, width: 1),
                              ),
                              child: const Text(
                                '선택약정',
                                style: TextStyle(
                                    color: AppTheme.seonyakBadge,
                                    fontSize: 11),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- 요약 영역 ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 할인 요약',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCapped
                          ? '총 할인율: $ratePct% (최대치 적용)'
                          : '총 할인율: $ratePct%',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasSeonyak
                                ? AppTheme.seonyakBadge.withAlpha(51)
                                : Colors.grey.withAlpha(51),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: hasSeonyak
                                  ? AppTheme.seonyakBadge
                                  : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            hasSeonyak ? '선택약정 포함' : '선택약정 미포함',
                            style: TextStyle(
                              color: hasSeonyak
                                  ? AppTheme.seonyakBadge
                                  : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedNames.join(' + '),
                        style: const TextStyle(
                            color: AppTheme.diffColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
