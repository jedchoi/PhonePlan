import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/purchase_result.dart';
import '../providers/device_provider.dart';
import '../providers/discount_program_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comparison_bar_chart.dart';

// 탭3: 비교 결과 화면 (전체 요약 + 상세)
class Tab3ResultsScreen extends StatefulWidget {
  const Tab3ResultsScreen({super.key});

  @override
  State<Tab3ResultsScreen> createState() => _Tab3ResultsScreenState();
}

class _Tab3ResultsScreenState extends State<Tab3ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비교 결과'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '전체 비교'),
            Tab(text: '상세 분석'),
          ],
        ),
      ),
      body: Consumer3<DeviceProvider, UserProfileProvider,
          DiscountProgramProvider>(
        builder: (context, deviceProv, profileProv, discountProv, _) {
          final devices = deviceProv.devices;
          if (devices.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 64, color: AppTheme.diffColor),
                  SizedBox(height: 16),
                  Text(
                    '기기 탭에서 기기를 추가해주세요',
                    style: TextStyle(color: AppTheme.diffColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final profile = profileProv.profile;
          final programs = discountProv.programs;
          final comparisons = deviceProv.compareAll(profile, programs);

          // 선택된 기기 초기화 (목록에서 삭제된 경우 처리)
          if (_selectedDeviceId != null &&
              !devices.any((d) => d.id == _selectedDeviceId)) {
            _selectedDeviceId = null;
          }
          _selectedDeviceId ??= devices.first.id;

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildOverviewTab(devices, comparisons),
              _buildDetailTab(devices, comparisons),
            ],
          );
        },
      ),
    );
  }

  // 뷰 A: 전체 기기 한눈에 비교
  Widget _buildOverviewTab(
    List<Device> devices,
    Map<String, DeviceComparison> comparisons,
  ) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    final methods = PurchaseMethod.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전체 기기 비교',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // 테이블 헤더
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF2C2C2C)),
                    ),
                  ),
                  children: [
                    _tableHeader('기기명'),
                    _tableHeader('자급제'),
                    _tableHeader('선택약정'),
                    _tableHeader('공시지원'),
                  ],
                ),
                ...devices.map((device) {
                  final comp = comparisons[device.id]!;
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF2C2C2C)),
                      ),
                    ),
                    children: [
                      // 기기명
                      InkWell(
                        onTap: () {
                          setState(() => _selectedDeviceId = device.id);
                          _tabCtrl.animateTo(1);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          child: Text(
                            device.name,
                            style: const TextStyle(
                                color: AppTheme.primary, fontSize: 12),
                          ),
                        ),
                      ),
                      // 각 방식 금액
                      ...methods.map((m) {
                        final result = comp.resultFor(m);
                        final isCheapest = m == comp.cheapest;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isCheapest)
                                const Text('🏆',
                                    style: TextStyle(fontSize: 10)),
                              Text(
                                fmt.format(result.total),
                                style: TextStyle(
                                  color: isCheapest
                                      ? AppTheme.cheapest
                                      : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: isCheapest
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '* 기기명을 탭하면 상세 분석 화면으로 이동합니다',
            style: TextStyle(color: AppTheme.diffColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 뷰 B: 특정 기기 상세 비교
  Widget _buildDetailTab(
    List<Device> devices,
    Map<String, DeviceComparison> comparisons,
  ) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    // 현재 선택된 기기 검증 (목록에 없으면 첫 번째로 폴백)
    if (!devices.any((d) => d.id == _selectedDeviceId)) {
      _selectedDeviceId = devices.first.id;
    }
    final comp = comparisons[_selectedDeviceId]!;
    final methods = PurchaseMethod.values;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기기 선택 드롭다운
          DropdownButton<String>(
            value: _selectedDeviceId,
            dropdownColor: AppTheme.cardBg,
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: AppTheme.primary),
            items: devices
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: (id) => setState(() => _selectedDeviceId = id),
          ),
          const SizedBox(height: 16),

          // 막대 그래프
          ComparisonBarChart(comparison: comp),
          const SizedBox(height: 16),

          // 차액 요약
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🏆 ', style: TextStyle(fontSize: 14)),
                    Text(
                      '${comp.cheapest.label}  ',
                      style: const TextStyle(
                          color: AppTheme.cheapest,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    Text(
                      '${fmt.format(comp.cheapestResult.total)}원',
                      style: const TextStyle(
                          color: AppTheme.cheapest,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...methods
                    .where((m) => m != comp.cheapest)
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${m.label}  +${fmt.format(comp.diffFrom(m))}원',
                            style: const TextStyle(
                                color: AppTheme.diffColor, fontSize: 13),
                          ),
                        )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 각 방식별 상세 내역 (ExpansionTile)
          const Text(
            '상세 내역',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...methods.map((m) {
            final result = comp.resultFor(m);
            final isCheapest = m == comp.cheapest;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                collapsedIconColor: Colors.white54,
                iconColor: AppTheme.primary,
                title: Row(
                  children: [
                    if (isCheapest)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Text('🏆', style: TextStyle(fontSize: 14)),
                      ),
                    Text(
                      m.label,
                      style: TextStyle(
                        color: isCheapest ? AppTheme.cheapest : Colors.white,
                        fontWeight: isCheapest
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${fmt.format(result.total)}원',
                      style: TextStyle(
                        color: isCheapest ? AppTheme.cheapest : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        _detailRow('기기값',
                            '${fmt.format(result.devicePrice)}원'),
                        if (result.planDetail.isNotEmpty)
                          _detailRow('요금제 비용', '${fmt.format(result.planCost)}원',
                              sub: result.planDetail),
                        if (result.addonCost > 0)
                          _detailRow('부가서비스 비용',
                              '${fmt.format(result.addonCost)}원'),
                        _detailRow('적용 할인율', result.rateExplanation),
                        const Divider(),
                        _detailRow(
                          '합계',
                          '${fmt.format(result.total)}원',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {String? sub, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: highlight ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: highlight ? AppTheme.cheapest : Colors.white,
                  fontSize: 13,
                  fontWeight:
                      highlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sub,
                style: const TextStyle(
                    color: AppTheme.diffColor, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
