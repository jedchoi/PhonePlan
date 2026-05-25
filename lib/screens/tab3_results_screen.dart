import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/device_offer.dart';
import '../models/purchase_result.dart';
import '../providers/device_provider.dart';
import '../providers/discount_program_provider.dart';
import '../providers/phone_preset_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/comparison_bar_chart.dart';

// 탭3: 비교 결과 화면 (전체 비교 + 상세 분석)
class Tab3ResultsScreen extends StatefulWidget {
  const Tab3ResultsScreen({super.key});

  @override
  State<Tab3ResultsScreen> createState() => _Tab3ResultsScreenState();
}

class _Tab3ResultsScreenState extends State<Tab3ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // 뷰 A: 기종별 매장 비교에서 선택된 기종
  String? _selectedPresetId;

  // 뷰 B: 상세 분석에서 선택된 오퍼
  DeviceOffer? _selectedOfferForDetail;

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
      body: Consumer4<DeviceProvider, PhonePresetProvider, UserProfileProvider,
          DiscountProgramProvider>(
        builder: (context, deviceProv, phoneProv, profileProv, discountProv, _) {
          final offers = deviceProv.offers;
          if (offers.isEmpty) {
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

          // 등록된 오퍼에서 unique 기종 추출 (등록 순서 유지)
          final presetIds = <String>[];
          for (final o in offers) {
            if (!presetIds.contains(o.phonePresetId)) {
              presetIds.add(o.phonePresetId);
            }
          }

          // 선택된 기종 초기화
          if (_selectedPresetId == null || !presetIds.contains(_selectedPresetId)) {
            _selectedPresetId = presetIds.first;
          }

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildOverviewTab(
                  offers, comparisons, phoneProv, presetIds),
              _buildDetailTab(
                  offers, comparisons, phoneProv, presetIds),
            ],
          );
        },
      ),
    );
  }

  // ─── 뷰 A: 기종별 매장 비교 ───
  Widget _buildOverviewTab(
    List<DeviceOffer> offers,
    Map<String, DeviceComparison> comparisons,
    PhonePresetProvider phoneProv,
    List<String> presetIds,
  ) {
    final fmt = NumberFormat('#,###', 'ko_KR');

    // 현재 기종의 오퍼들
    final currentOffers =
        offers.where((o) => o.phonePresetId == _selectedPresetId).toList();

    // 전체 행+방식 중 절대 최저가
    int? absMin;
    String? absMinOfferId;
    PurchaseMethod? absMinMethod;
    for (final o in currentOffers) {
      final comp = comparisons[o.id]!;
      for (final m in PurchaseMethod.values) {
        final t = comp.resultFor(m).total;
        if (absMin == null || t < absMin) {
          absMin = t;
          absMinOfferId = o.id;
          absMinMethod = m;
        }
      }
    }

    // 기종 목록 (기종 드롭다운용 - PhonePreset 이름)
    final presetItems = presetIds.map((id) {
      final preset = phoneProv.getById(id);
      return DropdownMenuItem<String>(
        value: id,
        child: Text(preset?.name ?? id),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기종 선택 드롭다운
          DropdownButton<String>(
            value: _selectedPresetId,
            dropdownColor: AppTheme.cardBg,
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: AppTheme.primary),
            isExpanded: true,
            items: presetItems,
            onChanged: (id) => setState(() => _selectedPresetId = id),
          ),
          const SizedBox(height: 16),

          if (currentOffers.isEmpty)
            const Center(
              child: Text('이 기종의 오퍼가 없습니다.',
                  style: TextStyle(color: AppTheme.diffColor)),
            )
          else ...[
            // 매장별 비교 표
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder(
                    horizontalInside: BorderSide(color: Colors.white12),
                    bottom: BorderSide(color: Colors.white12),
                  ),
                  children: [
                    // 헤더
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Color(0xFF2C2C2C))),
                      ),
                      children: [
                        _th('매장'),
                        _th('자급제'),
                        _th('선택약정'),
                        _th('공시지원'),
                        _th('최저'),
                      ],
                    ),
                    // 각 매장 행
                    ...currentOffers.map((offer) {
                      final comp = comparisons[offer.id]!;
                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(color: Color(0xFF2C2C2C))),
                        ),
                        children: [
                          // 매장명
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedOfferForDetail = offer;
                              });
                              _tabCtrl.animateTo(1);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Text(
                                offer.storeName,
                                style: const TextStyle(
                                    color: AppTheme.primary, fontSize: 12),
                              ),
                            ),
                          ),
                          // 자급제
                          _priceCell(
                            fmt,
                            offer,
                            comp,
                            PurchaseMethod.jagup,
                            absMinOfferId,
                            absMinMethod,
                            offer.jagupPrice == 0,
                          ),
                          // 선택약정
                          _priceCell(
                            fmt,
                            offer,
                            comp,
                            PurchaseMethod.seonyak,
                            absMinOfferId,
                            absMinMethod,
                            false,
                          ),
                          // 공시지원
                          _priceCell(
                            fmt,
                            offer,
                            comp,
                            PurchaseMethod.gongsi,
                            absMinOfferId,
                            absMinMethod,
                            offer.gongsiPrice == 0,
                          ),
                          // 최저 방식
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                            child: Column(
                              children: [
                                Text(
                                  comp.cheapest.label,
                                  style: const TextStyle(
                                      color: AppTheme.cheapest,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  fmt.format(comp.cheapestResult.total),
                                  style: const TextStyle(
                                      color: AppTheme.cheapest,
                                      fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '* 매장명을 탭하면 상세 분석으로 이동합니다',
              style: TextStyle(color: AppTheme.diffColor, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _priceCell(
    NumberFormat fmt,
    DeviceOffer offer,
    DeviceComparison comp,
    PurchaseMethod method,
    String? absMinOfferId,
    PurchaseMethod? absMinMethod,
    bool isEmpty,
  ) {
    if (isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text('-',
            style: TextStyle(color: Colors.white38, fontSize: 11),
            textAlign: TextAlign.center),
      );
    }

    final result = comp.resultFor(method);
    final isCheapest = method == comp.cheapest;
    final isAbsMin =
        offer.id == absMinOfferId && method == absMinMethod;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        children: [
          if (isCheapest)
            Text(
              isAbsMin ? '🏆★' : '🏆',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          Text(
            fmt.format(result.total),
            style: TextStyle(
              color: isCheapest ? AppTheme.cheapest : Colors.white70,
              fontSize: 11,
              fontWeight:
                  isCheapest ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── 뷰 B: 단일 오퍼 상세 분석 ───
  Widget _buildDetailTab(
    List<DeviceOffer> offers,
    Map<String, DeviceComparison> comparisons,
    PhonePresetProvider phoneProv,
    List<String> presetIds,
  ) {
    final fmt = NumberFormat('#,###', 'ko_KR');

    // 현재 기종의 오퍼들
    final currentOffers = _selectedPresetId != null
        ? offers.where((o) => o.phonePresetId == _selectedPresetId).toList()
        : offers;

    // 선택된 오퍼 검증
    if (_selectedOfferForDetail == null ||
        !currentOffers.any((o) => o.id == _selectedOfferForDetail!.id)) {
      _selectedOfferForDetail = currentOffers.isNotEmpty ? currentOffers.first : null;
    }

    final selectedOffer = _selectedOfferForDetail;
    if (selectedOffer == null) {
      return const Center(
        child: Text('오퍼를 선택하세요.', style: TextStyle(color: AppTheme.diffColor)),
      );
    }

    final comp = comparisons[selectedOffer.id]!;
    final methods = PurchaseMethod.values;
    final preset = phoneProv.getById(selectedOffer.phonePresetId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 매장 비교로 돌아가기
          TextButton.icon(
            onPressed: () => _tabCtrl.animateTo(0),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppTheme.diffColor),
            label: const Text('매장 비교로 돌아가기',
                style: TextStyle(color: AppTheme.diffColor)),
          ),
          const SizedBox(height: 8),

          // 기종+오퍼 선택 드롭다운
          if (preset != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                preset.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          DropdownButton<String>(
            value: selectedOffer.id,
            dropdownColor: AppTheme.cardBg,
            style: const TextStyle(color: Colors.white),
            underline: Container(height: 1, color: AppTheme.primary),
            isExpanded: true,
            items: currentOffers
                .map((o) => DropdownMenuItem(
                    value: o.id, child: Text(o.storeName)))
                .toList(),
            onChanged: (id) {
              if (id == null) return;
              setState(() {
                _selectedOfferForDetail =
                    currentOffers.firstWhere((o) => o.id == id);
              });
            },
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
                        color: isCheapest
                            ? AppTheme.cheapest
                            : Colors.white70,
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
                          _detailRow(
                              '요금제 비용',
                              '${fmt.format(result.planCost)}원',
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
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: highlight ? AppTheme.cheapest : Colors.white,
                    fontSize: 13,
                    fontWeight:
                        highlight ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.end,
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
