import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/addon_preset.dart';
import '../../providers/addon_preset_provider.dart';
import '../../theme/app_theme.dart';

// 설정 > 부가서비스 프리셋 관리 화면
class AddonManagementScreen extends StatelessWidget {
  const AddonManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    return Scaffold(
      appBar: AppBar(title: const Text('부가서비스 프리셋 관리')),
      body: Consumer<AddonPresetProvider>(
        builder: (context, prov, _) {
          final presets = prov.presets;
          return Column(
            children: [
              Expanded(
                child: presets.isEmpty
                    ? const Center(
                        child: Text('등록된 부가서비스가 없습니다.',
                            style: TextStyle(color: AppTheme.diffColor)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: presets.length,
                        itemBuilder: (context, index) {
                          final preset = presets[index];
                          return _buildPresetTile(
                              context, prov, preset, fmt);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(context, prov, null),
                    icon: const Icon(Icons.add, color: AppTheme.secondary),
                    label: const Text('부가서비스 추가',
                        style: TextStyle(color: AppTheme.secondary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetTile(
    BuildContext context,
    AddonPresetProvider prov,
    AddonPreset preset,
    NumberFormat fmt,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            const Icon(Icons.add_box_outlined, color: AppTheme.secondary),
        title: Text(
          preset.name ?? '이름 없음',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${fmt.format(preset.amount)}원/월',
          style: const TextStyle(color: AppTheme.diffColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => _showEditDialog(context, prov, preset),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, prov, preset),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    AddonPresetProvider prov,
    AddonPreset? existing,
  ) {
    final amountCtrl = TextEditingController(
        text: existing?.amount.toString() ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          existing == null ? '부가서비스 추가' : '부가서비스 편집',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: '서비스명 (선택)', hintText: '예: 넷플릭스'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: '월 요금 (필수)', suffixText: '원'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('올바른 금액을 입력해주세요.')),
                );
                return;
              }
              final name =
                  nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim();
              if (existing == null) {
                await prov.add(amount: amount, name: name);
              } else {
                await prov.update(
                    existing.copyWith(amount: amount, name: name, clearName: name == null));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AddonPresetProvider prov,
    AddonPreset preset,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('삭제 확인', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${preset.name ?? '이름 없음'}" 부가서비스를 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await prov.remove(preset.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
