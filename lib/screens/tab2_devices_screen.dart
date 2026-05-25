import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device_offer.dart';
import '../models/phone_preset.dart';
import '../providers/device_provider.dart';
import '../providers/discount_program_provider.dart';
import '../providers/phone_preset_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/device_summary_card.dart';
import 'tab2_device_edit_screen.dart';

// 탭2: 기기 오퍼 비교 목록 화면
class Tab2DevicesScreen extends StatefulWidget {
  const Tab2DevicesScreen({super.key});

  @override
  State<Tab2DevicesScreen> createState() => _Tab2DevicesScreenState();
}

class _Tab2DevicesScreenState extends State<Tab2DevicesScreen> {
  bool _groupByPhone = false; // 기종별 묶어보기 토글

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기기 비교'),
        actions: [
          IconButton(
            icon: Icon(
              _groupByPhone ? Icons.view_list : Icons.view_module,
              color: _groupByPhone ? AppTheme.primary : Colors.white54,
            ),
            tooltip: _groupByPhone ? '등록 순서로 보기' : '기종별 묶어보기',
            onPressed: () => setState(() => _groupByPhone = !_groupByPhone),
          ),
        ],
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
                  Icon(Icons.smartphone_outlined,
                      size: 64, color: AppTheme.diffColor),
                  SizedBox(height: 16),
                  Text(
                    '비교할 기기를 추가해보세요',
                    style: TextStyle(color: AppTheme.diffColor, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '우측 하단 + 버튼을 눌러 기기를 등록하세요',
                    style: TextStyle(color: Color(0xFF616161), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final profile = profileProv.profile;
          final programs = discountProv.programs;

          if (_groupByPhone) {
            return _buildGroupedList(
                context, deviceProv, phoneProv, offers, profile, programs);
          } else {
            return _buildFlatList(
                context, deviceProv, phoneProv, offers, profile, programs);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 등록 순서대로 리스트
  Widget _buildFlatList(
    BuildContext context,
    DeviceProvider deviceProv,
    PhonePresetProvider phoneProv,
    List<DeviceOffer> offers,
    dynamic profile,
    dynamic programs,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        final preset = phoneProv.getById(offer.phonePresetId);
        if (preset == null) return const SizedBox.shrink();
        final comparison = deviceProv.compare(offer, profile, programs);
        return OfferSummaryCard(
          offer: offer,
          phonePreset: preset,
          comparison: comparison,
          onTap: () => _openEdit(context, offer),
          onLongPress: () => _confirmDelete(context, deviceProv, offer, preset),
        );
      },
    );
  }

  // 기종별 묶어보기
  Widget _buildGroupedList(
    BuildContext context,
    DeviceProvider deviceProv,
    PhonePresetProvider phoneProv,
    List<DeviceOffer> offers,
    dynamic profile,
    dynamic programs,
  ) {
    // phonePresetId별 그룹핑 (등록 순서 유지)
    final groupKeys = <String>[];
    final groups = <String, List<DeviceOffer>>{};
    for (final offer in offers) {
      if (!groups.containsKey(offer.phonePresetId)) {
        groupKeys.add(offer.phonePresetId);
        groups[offer.phonePresetId] = [];
      }
      groups[offer.phonePresetId]!.add(offer);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final presetId in groupKeys) ...[
          // 섹션 헤더 = 기종명
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              phoneProv.getById(presetId)?.name ?? '알 수 없는 기종',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 하위 매장 카드
          for (final offer in groups[presetId]!) ...[
            Builder(builder: (context) {
              final preset = phoneProv.getById(offer.phonePresetId);
              if (preset == null) return const SizedBox.shrink();
              final comparison = deviceProv.compare(offer, profile, programs);
              return OfferSummaryCard(
                offer: offer,
                phonePreset: preset,
                comparison: comparison,
                onTap: () => _openEdit(context, offer),
                onLongPress: () =>
                    _confirmDelete(context, deviceProv, offer, preset),
              );
            }),
          ],
        ],
      ],
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const Tab2DeviceEditScreen(),
      ),
    );
  }

  void _openEdit(BuildContext context, DeviceOffer offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Tab2DeviceEditScreen(offer: offer),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DeviceProvider prov,
    DeviceOffer offer,
    PhonePreset preset,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('기기 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '${preset.name} (${offer.storeName})을(를) 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              prov.removeOffer(offer.id);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
