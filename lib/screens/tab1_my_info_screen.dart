import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/carrier.dart';
import '../providers/discount_program_provider.dart';
import '../providers/price_preset_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/carrier_data_service.dart';
import '../theme/app_theme.dart';

// 탭1: 내 정보 화면 (통신사 선택 + 요금제 카드 + 할인프로그램)
class Tab1MyInfoScreen extends StatefulWidget {
  const Tab1MyInfoScreen({super.key});

  @override
  State<Tab1MyInfoScreen> createState() => _Tab1MyInfoScreenState();
}

class _Tab1MyInfoScreenState extends State<Tab1MyInfoScreen> {
  List<Carrier> _carriers = [];
  bool _carriersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCarriers();
  }

  Future<void> _loadCarriers() async {
    final carriers = await CarrierDataService.loadCarriers();
    if (mounted) {
      setState(() {
        _carriers = carriers;
        _carriersLoaded = true;
      });
    }
  }

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

          // 할인율 계산
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
              // ─────────────────────────
              // 1. 통신사 선택
              // ─────────────────────────
              _buildSectionTitle('통신사'),
              const SizedBox(height: 10),
              _buildCarrierChips(profileProv, profile.currentCarrierId),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ─────────────────────────
              // 2. 현재 요금제
              // ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('현재 사용 중인 요금제'),
                  TextButton.icon(
                    onPressed: () => _showDirectInput(context, profileProv),
                    icon: const Icon(Icons.edit_outlined,
                        size: 15, color: AppTheme.secondary),
                    label: const Text('직접 입력',
                        style: TextStyle(
                            color: AppTheme.secondary, fontSize: 13)),
                    style: TextButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 현재 선택 표시
              if (profile.currentPlanAmount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.primary, size: 16),
                      const SizedBox(width: 6),
                      if (profile.currentPlanName != null) ...[
                        Expanded(
                          child: Text(
                            profile.currentPlanName!,
                            style: const TextStyle(
                                color: AppTheme.primary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${fmt.format(profile.currentPlanAmount)}원',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ] else
                        Text(
                          '${fmt.format(profile.currentPlanAmount)}원/월',
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 요금제 리스트 (통신사별 또는 프리셋)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _carriersLoaded
                    ? _buildPlanList(
                        context, profileProv, priceProv, profile, fmt)
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2)),
                      ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ─────────────────────────
              // 3. 할인프로그램
              // ─────────────────────────
              _buildSectionTitle('현재 적용 중인 할인프로그램'),
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
                          Text(program.name,
                              style:
                                  const TextStyle(color: Colors.white)),
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
                                color:
                                    AppTheme.seonyakBadge.withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppTheme.seonyakBadge,
                                    width: 1),
                              ),
                              child: const Text('선택약정',
                                  style: TextStyle(
                                      color: AppTheme.seonyakBadge,
                                      fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // ─────────────────────────
              // 4. 할인 요약
              // ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primary.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 할인 요약',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                      isCapped
                          ? '총 할인율: $ratePct% (최대치 적용)'
                          : '총 할인율: $ratePct%',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                    if (selectedNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(selectedNames.join(' + '),
                          style: const TextStyle(
                              color: AppTheme.diffColor, fontSize: 12)),
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

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold),
    );
  }

  // 통신사 선택 칩 (전체 / SKT / KT / LG U+)
  Widget _buildCarrierChips(
      UserProfileProvider profileProv, String? selectedId) {
    const carriers = [
      {'id': null, 'label': '전체', 'color': null},
      {'id': 'skt', 'label': 'SKT', 'color': Color(0xFFEF5350)},
      {'id': 'kt', 'label': 'KT', 'color': Color(0xFF78909C)},
      {'id': 'u_plus', 'label': 'LG U+', 'color': Color(0xFFEC407A)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: carriers.map((c) {
          final id = c['id'] as String?;
          final label = c['label'] as String;
          final accentColor = c['color'] as Color?;
          final isSelected = selectedId == id;

          final effectiveColor = accentColor ?? AppTheme.primary;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: effectiveColor.withAlpha(51),
              side: BorderSide(
                color: isSelected ? effectiveColor : const Color(0xFF424242),
              ),
              labelStyle: TextStyle(
                color: isSelected ? effectiveColor : Colors.white70,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => profileProv.setCarrierId(id),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 요금제 리스트 (통신사 선택 여부에 따라 다른 표시)
  Widget _buildPlanList(
    BuildContext context,
    UserProfileProvider profileProv,
    PricePresetProvider priceProv,
    dynamic profile,
    NumberFormat fmt,
  ) {
    final carrierId = profile.currentCarrierId as String?;

    if (carrierId == null) {
      // 전체: 사용자 등록 프리셋 표시
      final presets = priceProv.presets;
      if (presets.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '설정 탭에서 요금제를 추가하거나 직접 입력을 눌러주세요.',
            style: TextStyle(color: AppTheme.diffColor, fontSize: 13),
          ),
        );
      }
      return Column(
        children: presets.map((preset) {
          final isSelected = profile.currentPlanAmount == preset.amount &&
              profile.currentPlanName == null;
          return _PlanCard(
            planName: preset.name,
            amount: preset.amount,
            isSelected: isSelected,
            onTap: () =>
                profileProv.setPlanWithName(preset.amount, preset.name),
            fmt: fmt,
          );
        }).toList(),
      );
    }

    // 통신사 선택: 해당 통신사 요금제를 카테고리별로 표시
    final carrier = _carriers.where((c) => c.id == carrierId).firstOrNull;
    if (carrier == null) return const SizedBox.shrink();

    // 카테고리별 그룹핑
    final groups = <String, List<CarrierPlan>>{};
    for (final plan in carrier.plans) {
      groups.putIfAbsent(plan.category, () => []).add(plan);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        final category = entry.key;
        final plans = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 헤더
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _carrierColor(carrierId),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _categoryLabel(category),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ...plans.map((plan) {
              final isSelected = profile.currentPlanAmount == plan.amount &&
                  profile.currentPlanName == plan.name;
              return _PlanCard(
                planName: plan.name,
                amount: plan.amount,
                isSelected: isSelected,
                onTap: () =>
                    profileProv.setPlanWithName(plan.amount, plan.name),
                fmt: fmt,
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Color _carrierColor(String? carrierId) {
    switch (carrierId) {
      case 'skt':
        return const Color(0xFFEF5350);
      case 'kt':
        return const Color(0xFF78909C);
      case 'u_plus':
        return const Color(0xFFEC407A);
      default:
        return AppTheme.primary;
    }
  }

  String _categoryLabel(String category) {
    // 카테고리 코드를 읽기 좋은 한국어로 변환
    const labels = {
      '5G': '5G',
      '5G_청년': '5G 청년',
      '5G_청소년': '5G 청소년',
      '5G_시니어': '5G 시니어',
      '5G_특화': '5G 특화',
      '5G_유쓰': '5G 유쓰',
      '5G_키즈': '5G 키즈',
      '다이렉트': '다이렉트',
      '다이렉트_청년': '다이렉트 청년',
      '온라인전용': '온라인 전용',
      'LTE': 'LTE',
    };
    return labels[category] ?? category;
  }

  // 직접 입력 다이얼로그
  void _showDirectInput(
      BuildContext context, UserProfileProvider profileProv) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('요금제 금액 직접 입력',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
              labelText: '금액', suffixText: '원'),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                profileProv.setPlanAmount(val); // 이름 null로 저장
                Navigator.pop(ctx);
              }
            },
            child: const Text('확인',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

// 요금제 카드 위젯
class _PlanCard extends StatelessWidget {
  final String? planName;
  final int amount;
  final bool isSelected;
  final VoidCallback onTap;
  final NumberFormat fmt;

  const _PlanCard({
    required this.planName,
    required this.amount,
    required this.isSelected,
    required this.onTap,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: isSelected
          ? AppTheme.primary.withAlpha(30)
          : AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: planName != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${fmt.format(amount)}원',
                            style: const TextStyle(
                                color: AppTheme.diffColor,
                                fontSize: 13),
                          ),
                        ],
                      )
                    : Text(
                        '${fmt.format(amount)}원',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
