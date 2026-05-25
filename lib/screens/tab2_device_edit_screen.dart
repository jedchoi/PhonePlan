import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/addon_preset.dart';
import '../models/device.dart';
import '../providers/addon_preset_provider.dart';
import '../providers/device_provider.dart';
import '../providers/price_preset_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/price_chip_selector.dart';

// 탭2: 기기 추가/편집 화면
class Tab2DeviceEditScreen extends StatefulWidget {
  final Device? device; // null이면 추가, 있으면 편집

  const Tab2DeviceEditScreen({super.key, this.device});

  @override
  State<Tab2DeviceEditScreen> createState() => _Tab2DeviceEditScreenState();
}

class _Tab2DeviceEditScreenState extends State<Tab2DeviceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  // 자급제
  final _jagupPriceCtrl = TextEditingController();

  // 선택약정
  final _seonyakPriceCtrl = TextEditingController();
  int? _seonyakRequiredPlan;
  int _seonyakRequiredMonths = 1;
  final List<RequiredAddon> _seonyakAddons = [];

  // 공시지원
  final _gongsiPriceCtrl = TextEditingController();
  int? _gongsiRequiredPlan;
  int _gongsiRequiredMonths = 1;
  final List<RequiredAddon> _gongsiAddons = [];

  final NumberFormat _fmt = NumberFormat('#,###', 'ko_KR');

  @override
  void initState() {
    super.initState();
    final d = widget.device;
    if (d != null) {
      _nameCtrl.text = d.name;
      _jagupPriceCtrl.text = d.jagupPrice.toString();
      _seonyakPriceCtrl.text = d.seonyakPrice.toString();
      _seonyakRequiredPlan = d.seonyakRequiredPlan > 0 ? d.seonyakRequiredPlan : null;
      _seonyakRequiredMonths = d.seonyakRequiredMonths;
      _seonyakAddons.addAll(d.seonyakAddons);
      _gongsiPriceCtrl.text = d.gongsiPrice.toString();
      _gongsiRequiredPlan = d.gongsiRequiredPlan > 0 ? d.gongsiRequiredPlan : null;
      _gongsiRequiredMonths = d.gongsiRequiredMonths;
      _gongsiAddons.addAll(d.gongsiAddons);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _jagupPriceCtrl.dispose();
    _seonyakPriceCtrl.dispose();
    _gongsiPriceCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _nameCtrl.text.trim().isNotEmpty &&
        _jagupPriceCtrl.text.isNotEmpty &&
        _seonyakPriceCtrl.text.isNotEmpty &&
        _gongsiPriceCtrl.text.isNotEmpty;
  }

  Future<void> _save() async {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기기명과 모든 기기 현금가를 입력해주세요.')),
      );
      return;
    }
    final deviceProv = context.read<DeviceProvider>();
    final device = Device(
      id: widget.device?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      jagupPrice: int.parse(_jagupPriceCtrl.text.replaceAll(',', '')),
      seonyakPrice: int.parse(_seonyakPriceCtrl.text.replaceAll(',', '')),
      seonyakRequiredPlan: _seonyakRequiredPlan ?? 0,
      seonyakRequiredMonths: _seonyakRequiredMonths,
      seonyakAddons: List.from(_seonyakAddons),
      gongsiPrice: int.parse(_gongsiPriceCtrl.text.replaceAll(',', '')),
      gongsiRequiredPlan: _gongsiRequiredPlan ?? 0,
      gongsiRequiredMonths: _gongsiRequiredMonths,
      gongsiAddons: List.from(_gongsiAddons),
    );

    if (widget.device == null) {
      await deviceProv.add(device);
    } else {
      await deviceProv.update(device);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.device != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '기기 편집' : '기기 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 기기명
            _buildTextField(controller: _nameCtrl, label: '기기명', hint: '예: 갤럭시 S26'),
            const SizedBox(height: 20),

            // 자급제 섹션
            _buildSection(
              title: '자급제',
              icon: Icons.shopping_bag_outlined,
              children: [
                _buildPriceField(
                    controller: _jagupPriceCtrl, label: '기기 현금가'),
              ],
            ),
            const SizedBox(height: 16),

            // 선택약정 섹션
            _buildSection(
              title: '선택약정',
              icon: Icons.assignment_outlined,
              children: [
                _buildPriceField(
                    controller: _seonyakPriceCtrl, label: '기기 현금가'),
                const SizedBox(height: 12),
                _buildPlanSelector(
                  label: '필수 요금제',
                  selected: _seonyakRequiredPlan,
                  onSelected: (v) => setState(() => _seonyakRequiredPlan = v),
                ),
                const SizedBox(height: 12),
                _buildMonthsSlider(
                  label: '필수 요금제 유지 개월수',
                  value: _seonyakRequiredMonths,
                  onChanged: (v) =>
                      setState(() => _seonyakRequiredMonths = v),
                ),
                const SizedBox(height: 12),
                _buildAddonList(
                  addons: _seonyakAddons,
                  onAdd: () => _showAddonPicker(_seonyakAddons),
                  onRemove: (i) => setState(() => _seonyakAddons.removeAt(i)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 공시지원 섹션
            _buildSection(
              title: '공시지원',
              icon: Icons.local_offer_outlined,
              children: [
                _buildPriceField(
                    controller: _gongsiPriceCtrl,
                    label: '기기 현금가 (공시지원금 차감 후)'),
                const SizedBox(height: 12),
                _buildPlanSelector(
                  label: '필수 요금제',
                  selected: _gongsiRequiredPlan,
                  onSelected: (v) => setState(() => _gongsiRequiredPlan = v),
                ),
                const SizedBox(height: 12),
                _buildMonthsSlider(
                  label: '필수 요금제 유지 개월수',
                  value: _gongsiRequiredMonths,
                  onChanged: (v) =>
                      setState(() => _gongsiRequiredMonths = v),
                ),
                const SizedBox(height: 12),
                _buildAddonList(
                  addons: _gongsiAddons,
                  onAdd: () => _showAddonPicker(_gongsiAddons),
                  onRemove: (i) => setState(() => _gongsiAddons.removeAt(i)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, suffixText: '원'),
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildPlanSelector({
    required String label,
    required int? selected,
    required ValueChanged<int> onSelected,
  }) {
    return Consumer<PricePresetProvider>(
      builder: (context, priceProv, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            PriceChipSelector(
              presets: priceProv.presets,
              selectedAmount: selected,
              onSelected: onSelected,
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '선택: ${_fmt.format(selected)}원',
                  style: const TextStyle(
                      color: AppTheme.primary, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMonthsSlider({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(
              '$value개월',
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 24,
          divisions: 23,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _buildAddonList({
    required List<RequiredAddon> addons,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('필수 부가서비스',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 6),
        ...addons.asMap().entries.map((entry) {
          final i = entry.key;
          final addon = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_fmt.format(addon.amount)}원 × ${addon.months}개월',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '합계 ${_fmt.format(addon.amount * addon.months)}원',
                  style: const TextStyle(
                      color: AppTheme.diffColor, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                  onPressed: () => onRemove(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: AppTheme.secondary, size: 18),
          label: const Text('부가서비스 추가',
              style: TextStyle(color: AppTheme.secondary)),
        ),
      ],
    );
  }

  void _showAddonPicker(List<RequiredAddon> targetList) {
    final addonProv =
        Provider.of<AddonPresetProvider>(context, listen: false);
    final presets = addonProv.presets;

    AddonPreset? selectedPreset;
    final monthsCtrl = TextEditingController(text: '1');
    final amountCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '부가서비스 추가',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (presets.isNotEmpty) ...[
                    const Text('프리셋 선택',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: presets.map((preset) {
                        final isSelected = selectedPreset?.id == preset.id;
                        return ChoiceChip(
                          label: Text(
                            '${preset.name ?? ''} ${_fmt.format(preset.amount)}원',
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            setModalState(() {
                              selectedPreset = preset;
                              amountCtrl.text = preset.amount.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              labelText: '월 요금 (원)', suffixText: '원'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: monthsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                              labelText: '의무 개월수', suffixText: '개월'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = int.tryParse(amountCtrl.text);
                        final months = int.tryParse(monthsCtrl.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('월 요금을 입력해주세요.')),
                          );
                          return;
                        }
                        if (months == null || months < 1 || months > 24) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('개월수는 1~24 사이로 입력해주세요.')),
                          );
                          return;
                        }
                        setState(() {
                          targetList.add(RequiredAddon(
                            amount: amount,
                            months: months,
                            presetId: selectedPreset?.id,
                          ));
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('추가'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
