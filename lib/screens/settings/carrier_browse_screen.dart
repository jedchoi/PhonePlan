import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/carrier.dart';
import '../../providers/addon_preset_provider.dart';
import '../../providers/price_preset_provider.dart';
import '../../services/carrier_data_service.dart';
import '../../theme/app_theme.dart';

// 설정 > 통신사 둘러보기 화면
class CarrierBrowseScreen extends StatefulWidget {
  const CarrierBrowseScreen({super.key});

  @override
  State<CarrierBrowseScreen> createState() => _CarrierBrowseScreenState();
}

class _CarrierBrowseScreenState extends State<CarrierBrowseScreen> {
  List<Carrier>? _carriers;
  Carrier? _selectedCarrier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final carriers = await CarrierDataService.loadCarriers();
    if (mounted) {
      setState(() => _carriers = carriers);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carriers == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedCarrier == null) {
      return _buildCarrierSelectionScreen();
    } else {
      return _buildCarrierDetailScreen(_selectedCarrier!);
    }
  }

  // 통신사 선택 화면
  Widget _buildCarrierSelectionScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('통신사 둘러보기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              '통신사를 선택하면 요금제와 부가서비스를 볼 수 있습니다.',
              style: TextStyle(color: AppTheme.diffColor, fontSize: 13),
            ),
          ),
          for (final carrier in _carriers!)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedCarrier = carrier),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          carrier.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '요금제 ${carrier.plans.length}개  부가서비스 ${carrier.addons.length}개',
                        style: const TextStyle(
                            color: AppTheme.diffColor, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppTheme.diffColor),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 통신사 상세 화면 (요금제 / 부가서비스 탭)
  Widget _buildCarrierDetailScreen(Carrier carrier) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(carrier.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedCarrier = null),
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '요금제'),
              Tab(text: '부가서비스'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PlansTab(carrier: carrier),
            _AddonsTab(carrier: carrier),
          ],
        ),
      ),
    );
  }
}

// 요금제 탭
class _PlansTab extends StatelessWidget {
  final Carrier carrier;
  const _PlansTab({required this.carrier});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    final priceProv = context.watch<PricePresetProvider>();

    // 카테고리별 그룹핑
    final grouped = <String, List<CarrierPlan>>{};
    for (final plan in carrier.plans) {
      grouped.putIfAbsent(plan.category, () => []).add(plan);
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final entry in grouped.entries)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              collapsedIconColor: Colors.white54,
              iconColor: AppTheme.primary,
              title: Text(
                _categoryLabel(entry.key),
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
              children: [
                for (final plan in entry.value)
                  ListTile(
                    title: Text(plan.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                    subtitle: Text(
                      '${fmt.format(plan.amount)}원/월',
                      style: const TextStyle(
                          color: AppTheme.cheapest, fontSize: 13),
                    ),
                    trailing: _AddButton(
                      label: plan.name,
                      amount: plan.amount,
                      alreadyAdded: priceProv.presets
                          .any((p) => p.amount == plan.amount),
                      onAdd: () async {
                        await priceProv.addFromCarrier(
                            plan.name, plan.amount);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    '${plan.name} 요금제를 프리셋에 추가했습니다.')),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _categoryLabel(String cat) {
    const map = {
      '5G': '5G',
      '5G_청년': '5G 청년',
      '5G_청소년': '5G 청소년',
      '5G_시니어': '5G 시니어',
      '5G_특화': '5G 특화',
      '5G_유쓰': '5G 유쓰',
      '5G_키즈': '5G 키즈',
      'LTE': 'LTE',
      '다이렉트': '다이렉트',
      '다이렉트_청년': '다이렉트 청년',
      '온라인전용': '온라인 전용',
    };
    return map[cat] ?? cat;
  }
}

// 부가서비스 탭
class _AddonsTab extends StatelessWidget {
  final Carrier carrier;
  const _AddonsTab({required this.carrier});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    final addonProv = context.watch<AddonPresetProvider>();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: carrier.addons.length,
      itemBuilder: (context, index) {
        final addon = carrier.addons[index];
        final alreadyAdded = addonProv.presets
            .any((p) => p.amount == addon.amount && p.name == addon.name);
        return ListTile(
          title: Text(addon.name,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${fmt.format(addon.amount)}원/월',
                  style: const TextStyle(
                      color: AppTheme.cheapest, fontSize: 13)),
              if (addon.desc.isNotEmpty)
                Text(addon.desc,
                    style: const TextStyle(
                        color: AppTheme.diffColor, fontSize: 11)),
            ],
          ),
          isThreeLine: addon.desc.isNotEmpty,
          trailing: _AddButton(
            label: addon.name,
            amount: addon.amount,
            alreadyAdded: alreadyAdded,
            onAdd: () async {
              await addonProv.addFromCarrier(addon.name, addon.amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${addon.name} 부가서비스를 프리셋에 추가했습니다.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// 추가 버튼 위젯
class _AddButton extends StatelessWidget {
  final String label;
  final int amount;
  final bool alreadyAdded;
  final VoidCallback onAdd;

  const _AddButton({
    required this.label,
    required this.amount,
    required this.alreadyAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (alreadyAdded) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.cheapest, size: 16),
          SizedBox(width: 4),
          Text('추가됨', style: TextStyle(color: AppTheme.cheapest, fontSize: 12)),
        ],
      );
    }
    return TextButton(
      onPressed: onAdd,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('+추가', style: TextStyle(color: AppTheme.secondary)),
    );
  }
}
