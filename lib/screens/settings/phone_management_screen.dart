import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/phone_preset.dart';
import '../../providers/phone_preset_provider.dart';
import '../../theme/app_theme.dart';

// 설정 > 기종 관리 화면
class PhoneManagementScreen extends StatelessWidget {
  const PhoneManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기종 관리')),
      body: Consumer<PhonePresetProvider>(
        builder: (context, prov, _) {
          final presets = prov.presets;

          if (presets.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final added = await prov.ensureDefaultPhonesExist();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(added > 0
                              ? '$added개의 기본 기종이 추가되었습니다.'
                              : '이미 모든 기본 기종이 등록되어 있습니다.'),
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    },
                    icon: const Icon(Icons.refresh,
                        color: AppTheme.secondary, size: 18),
                    label: const Text('기본 기종 불러오기',
                        style: TextStyle(color: AppTheme.secondary)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.secondary)),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text('등록된 기종이 없습니다.',
                        style: TextStyle(color: AppTheme.diffColor)),
                  ),
                ),
              ],
            );
          }

          // 제조사별 그룹핑: 삼성 → 애플 → 기타
          final grouped = <String, List<PhonePreset>>{};
          for (final p in presets) {
            final mfr = p.manufacturer ?? '기타';
            grouped.putIfAbsent(mfr, () => []).add(p);
          }
          // 그룹 내 출시일 역순 정렬
          for (final key in grouped.keys) {
            grouped[key]!.sort((a, b) {
              final da = a.releaseDate ?? '';
              final db = b.releaseDate ?? '';
              return db.compareTo(da);
            });
          }
          // 그룹 순서: 삼성 → 애플 → 기타
          const groupOrder = ['삼성', '애플', '기타'];
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) {
              final ia = groupOrder.indexOf(a);
              final ib = groupOrder.indexOf(b);
              final ra = ia == -1 ? 99 : ia;
              final rb = ib == -1 ? 99 : ib;
              return ra.compareTo(rb);
            });

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 기본 기종 다시 불러오기 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final added = await prov.ensureDefaultPhonesExist();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          added > 0
                              ? '$added개의 기본 기종이 추가되었습니다.'
                              : '이미 모든 기본 기종이 등록되어 있습니다.',
                        ),
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                  icon: const Icon(Icons.refresh,
                      color: AppTheme.secondary, size: 18),
                  label: const Text('기본 기종 다시 불러오기',
                      style: TextStyle(color: AppTheme.secondary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.secondary),
                  ),
                ),
              ),
              const Divider(height: 16),
              for (final mfr in sortedKeys) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    mfr,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (final preset in grouped[mfr]!)
                  _PresetTile(preset: preset, prov: prov),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showEditDialog(BuildContext context, PhonePreset? existing) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _PhonePresetDialog(existing: existing),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final PhonePreset preset;
  final PhonePresetProvider prov;

  const _PresetTile({required this.preset, required this.prov});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(preset.name, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        [
          if (preset.releaseDate != null) preset.releaseDate!,
          if (preset.defaultJagupPrice != null)
            '자급제 기본가: ${_fmt(preset.defaultJagupPrice!)}원',
        ].join('  ·  '),
        style: const TextStyle(color: AppTheme.diffColor, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.primary, size: 20),
            onPressed: () => _showEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _showEdit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _PhonePresetDialog(existing: preset),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('기종 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '${preset.name}을(를) 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              prov.removePreset(preset.id);
              Navigator.pop(ctx);
            },
            child:
                const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _PhonePresetDialog extends StatefulWidget {
  final PhonePreset? existing;
  const _PhonePresetDialog({this.existing});

  @override
  State<_PhonePresetDialog> createState() => _PhonePresetDialogState();
}

class _PhonePresetDialogState extends State<_PhonePresetDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _manufacturer;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _nameCtrl.text = p.name;
      _manufacturer = p.manufacturer;
      if (p.defaultJagupPrice != null) {
        _priceCtrl.text = p.defaultJagupPrice.toString();
      }
      if (p.releaseDate != null) _dateCtrl.text = p.releaseDate!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<PhonePresetProvider>();
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: AppTheme.cardBg,
      title: Text(
        isEdit ? '기종 편집' : '기종 추가',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: '기종명 *'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // 제조사
            const Text('제조사',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _manufacturer,
              dropdownColor: AppTheme.cardBg,
              style: const TextStyle(color: Colors.white),
              hint: const Text('선택 (선택사항)',
                  style: TextStyle(color: Colors.white38)),
              underline: Container(height: 1, color: AppTheme.primary),
              items: const [
                DropdownMenuItem(value: '삼성', child: Text('삼성')),
                DropdownMenuItem(value: '애플', child: Text('애플')),
                DropdownMenuItem(value: '기타', child: Text('기타')),
              ],
              onChanged: (v) => setState(() => _manufacturer = v),
            ),
            const SizedBox(height: 12),
            // 자급제 기본가 (선택)
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: '자급제 기본가 (선택)', suffixText: '원'),
            ),
            const SizedBox(height: 12),
            // 출시일 (선택)
            TextField(
              controller: _dateCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '출시일 (선택)',
                hintText: '예: 2025-02',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _nameCtrl.text.trim().isEmpty
              ? null
              : () async {
                  final name = _nameCtrl.text.trim();
                  final price = int.tryParse(_priceCtrl.text);
                  final date =
                      _dateCtrl.text.trim().isEmpty ? null : _dateCtrl.text.trim();
                  if (isEdit) {
                    await prov.updatePreset(widget.existing!.copyWith(
                      name: name,
                      manufacturer: _manufacturer,
                      defaultJagupPrice: price,
                      releaseDate: date,
                      clearDefaultJagupPrice: price == null,
                      clearManufacturer: _manufacturer == null,
                      clearReleaseDate: date == null,
                    ));
                  } else {
                    await prov.addPreset(PhonePreset(
                      id: '',
                      name: name,
                      manufacturer: _manufacturer,
                      defaultJagupPrice: price,
                      releaseDate: date,
                    ));
                  }
                  if (context.mounted) Navigator.pop(context);
                },
          child: Text(
            '저장',
            style: TextStyle(
                color: _nameCtrl.text.trim().isEmpty
                    ? Colors.white38
                    : AppTheme.primary),
          ),
        ),
      ],
    );
  }
}
