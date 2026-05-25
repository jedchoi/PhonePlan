import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/price_preset.dart';
import '../theme/app_theme.dart';

// 요금제 금액 칩 선택 위젯
class PriceChipSelector extends StatelessWidget {
  final List<PricePreset> presets;
  final int? selectedAmount;
  final ValueChanged<int> onSelected;

  const PriceChipSelector({
    super.key,
    required this.presets,
    required this.selectedAmount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'ko_KR');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...presets.map((preset) {
          final isSelected = selectedAmount == preset.amount;
          return ChoiceChip(
            label: Text('${fmt.format(preset.amount)}원'),
            selected: isSelected,
            selectedColor: AppTheme.primary.withAlpha(51),
            onSelected: (_) => onSelected(preset.amount),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : const Color(0xFF424242),
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppTheme.primary : Colors.white,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }),
        // 직접 입력 칩
        ActionChip(
          label: const Text('+ 직접 입력'),
          backgroundColor: const Color(0xFF2A2A2A),
          side: const BorderSide(color: Color(0xFF424242)),
          labelStyle: const TextStyle(color: AppTheme.secondary),
          onPressed: () => _showCustomInput(context),
        ),
      ],
    );
  }

  void _showCustomInput(BuildContext context) {
    final controller = TextEditingController(
      text: selectedAmount != null &&
              !presets.any((p) => p.amount == selectedAmount)
          ? selectedAmount.toString()
          : '',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title:
            const Text('요금제 금액 직접 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '금액 (원)',
            suffixText: '원',
          ),
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
                onSelected(val);
                Navigator.pop(ctx);
              }
            },
            child:
                const Text('확인', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}
