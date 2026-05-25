import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/discount_program.dart';
import '../../providers/discount_program_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../theme/app_theme.dart';

// 설정 > 할인프로그램 관리 화면
class DiscountManagementScreen extends StatelessWidget {
  const DiscountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('할인프로그램 관리')),
      body: Consumer<DiscountProgramProvider>(
        builder: (context, prov, _) {
          final programs = prov.programs;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ...programs.map((p) => _buildProgramTile(context, prov, p)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(context, prov, null),
                  icon: const Icon(Icons.add, color: AppTheme.secondary),
                  label: const Text('할인프로그램 추가',
                      style: TextStyle(color: AppTheme.secondary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgramTile(
    BuildContext context,
    DiscountProgramProvider prov,
    DiscountProgram p,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(p.name, style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            Text(
              '${(p.rate * 100).round()}%',
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
            if (p.isSeonyak) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.seonyakBadge.withAlpha(51),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.seonyakBadge),
                ),
                child: const Text(
                  '선택약정',
                  style:
                      TextStyle(color: AppTheme.seonyakBadge, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => _showEditDialog(context, prov, p),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, prov, p),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    DiscountProgramProvider prov,
    DiscountProgram? existing,
  ) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final rateCtrl = TextEditingController(
        text: existing != null
            ? (existing.rate * 100).round().toString()
            : '');
    bool isSeonyak = existing?.isSeonyak ?? false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            existing == null ? '할인프로그램 추가' : '할인프로그램 편집',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: '할인 이름 (필수)'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: '할인율 (0~100)', suffixText: '%'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('선택약정 여부',
                      style: TextStyle(color: Colors.white70)),
                  Switch(
                    value: isSeonyak,
                    onChanged: (v) => setDialogState(() => isSeonyak = v),
                  ),
                ],
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
                final name = nameCtrl.text.trim();
                final ratePct = int.tryParse(rateCtrl.text);
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이름을 입력해주세요.')),
                  );
                  return;
                }
                if (ratePct == null || ratePct < 0 || ratePct > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('할인율은 0~100 사이로 입력해주세요.')),
                  );
                  return;
                }
                final rate = ratePct / 100.0;
                if (existing == null) {
                  await prov.add(name: name, rate: rate, isSeonyak: isSeonyak);
                } else {
                  await prov.update(existing.copyWith(
                      name: name, rate: rate, isSeonyak: isSeonyak));
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('저장',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DiscountProgramProvider prov,
    DiscountProgram p,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('삭제 확인', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${p.name}" 할인프로그램을 삭제하시겠습니까?\n탭1에서 선택된 경우 자동으로 해제됩니다.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // 선택 목록에서도 제거
              if (context.mounted) {
                context.read<UserProfileProvider>().removeDiscountId(p.id);
              }
              await prov.remove(p.id);
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
