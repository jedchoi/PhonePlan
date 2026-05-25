import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/addon_preset.dart';
import '../models/device.dart';
import '../models/device_offer.dart';
import '../models/phone_preset.dart';
import '../providers/addon_preset_provider.dart';
import '../providers/device_provider.dart';
import '../providers/phone_preset_provider.dart';
import '../providers/price_preset_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/price_chip_selector.dart';

// 탭2: 기기 오퍼 추가/편집 화면
class Tab2DeviceEditScreen extends StatefulWidget {
  final DeviceOffer? offer; // null이면 추가, 있으면 편집

  const Tab2DeviceEditScreen({super.key, this.offer});

  @override
  State<Tab2DeviceEditScreen> createState() => _Tab2DeviceEditScreenState();
}

class _Tab2DeviceEditScreenState extends State<Tab2DeviceEditScreen> {
  // 기종 선택
  PhonePreset? _selectedPreset;
  bool _jagupAutoFilled = false; // 자급제 가격 자동 채움 여부

  // 매장명
  final _storeCtrl = TextEditingController();

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
    final o = widget.offer;
    if (o != null) {
      // 편집 모드: 기존 데이터 채우기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final phoneProv =
            Provider.of<PhonePresetProvider>(context, listen: false);
        setState(() {
          _selectedPreset = phoneProv.getById(o.phonePresetId);
        });
      });
      _storeCtrl.text = o.storeName;
      _jagupPriceCtrl.text = o.jagupPrice.toString();
      _seonyakPriceCtrl.text = o.seonyakPrice.toString();
      _seonyakRequiredPlan =
          o.seonyakRequiredPlan > 0 ? o.seonyakRequiredPlan : null;
      _seonyakRequiredMonths = o.seonyakRequiredMonths;
      _seonyakAddons.addAll(o.seonyakAddons);
      _gongsiPriceCtrl.text = o.gongsiPrice.toString();
      _gongsiRequiredPlan =
          o.gongsiRequiredPlan > 0 ? o.gongsiRequiredPlan : null;
      _gongsiRequiredMonths = o.gongsiRequiredMonths;
      _gongsiAddons.addAll(o.gongsiAddons);
    }
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _jagupPriceCtrl.dispose();
    _seonyakPriceCtrl.dispose();
    _gongsiPriceCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _selectedPreset != null &&
        _storeCtrl.text.trim().isNotEmpty &&
        _jagupPriceCtrl.text.isNotEmpty &&
        _seonyakPriceCtrl.text.isNotEmpty &&
        _gongsiPriceCtrl.text.isNotEmpty;
  }

  Future<void> _save() async {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기종, 매장명과 모든 기기 현금가를 입력해주세요.')),
      );
      return;
    }
    final deviceProv = context.read<DeviceProvider>();
    final phoneProv = context.read<PhonePresetProvider>();

    final offer = DeviceOffer(
      id: widget.offer?.id ?? const Uuid().v4(),
      phonePresetId: _selectedPreset!.id,
      storeName: _storeCtrl.text.trim(),
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

    if (widget.offer == null) {
      await deviceProv.addOffer(offer, phoneProv);
    } else {
      await deviceProv.updateOffer(offer, phoneProv);
    }
    if (mounted) Navigator.pop(context);
  }

  // 공시지원 → 선택약정 복사
  void _copyGongsiToSeonyak() {
    setState(() {
      _seonyakRequiredPlan = _gongsiRequiredPlan;
      _seonyakRequiredMonths = _gongsiRequiredMonths;
      _seonyakAddons
        ..clear()
        ..addAll(_gongsiAddons.map((a) => RequiredAddon(
              amount: a.amount,
              months: a.months,
              presetId: a.presetId,
            )));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('공시지원 조건을 선택약정에 복사했습니다.')),
    );
  }

  // 선택약정 → 공시지원 복사
  void _copySeonyakToGongsi() {
    setState(() {
      _gongsiRequiredPlan = _seonyakRequiredPlan;
      _gongsiRequiredMonths = _seonyakRequiredMonths;
      _gongsiAddons
        ..clear()
        ..addAll(_seonyakAddons.map((a) => RequiredAddon(
              amount: a.amount,
              months: a.months,
              presetId: a.presetId,
            )));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택약정 조건을 공시지원에 복사했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.offer != null;
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 기종 선택
          _buildPhoneSelector(),
          const SizedBox(height: 16),

          // 2. 매장명 입력
          _buildTextField(
            controller: _storeCtrl,
            label: '매장명',
            hint: '예: 강남 A매장, 쿠팡, 공식몰',
          ),
          const SizedBox(height: 20),

          // 3. 자급제 섹션
          _buildSection(
            title: '자급제',
            icon: Icons.shopping_bag_outlined,
            extraHeader: null,
            children: [
              _buildPriceFieldWithAuto(
                controller: _jagupPriceCtrl,
                label: '기기 현금가',
                isAutoFilled: _jagupAutoFilled,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. 선택약정 섹션 (↻ 공시지원 조건 복사 버튼)
          _buildSection(
            title: '선택약정',
            icon: Icons.assignment_outlined,
            extraHeader: IconButton(
              icon: const Icon(Icons.sync, size: 18),
              tooltip: '공시지원 조건 복사',
              color: _gongsiRequiredPlan != null
                  ? AppTheme.secondary
                  : Colors.white30,
              onPressed: _gongsiRequiredPlan != null ? _copyGongsiToSeonyak : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
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

          // 5. 공시지원 섹션 (↻ 선택약정 조건 복사 버튼)
          _buildSection(
            title: '공시지원',
            icon: Icons.local_offer_outlined,
            extraHeader: IconButton(
              icon: const Icon(Icons.sync, size: 18),
              tooltip: '선택약정 조건 복사',
              color: _seonyakRequiredPlan != null
                  ? AppTheme.secondary
                  : Colors.white30,
              onPressed:
                  _seonyakRequiredPlan != null ? _copySeonyakToGongsi : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            children: [
              _buildPriceField(
                controller: _gongsiPriceCtrl,
                label: '기기 현금가 (공시지원금 차감 후)',
              ),
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
    );
  }

  // 기종 선택 위젯
  Widget _buildPhoneSelector() {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPhonePicker(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.smartphone, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: _selectedPreset == null
                    ? const Text(
                        '기종을 선택하세요 *',
                        style: TextStyle(color: Colors.white54),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPreset!.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          if (_selectedPreset!.manufacturer != null)
                            Text(
                              _selectedPreset!.manufacturer!,
                              style: const TextStyle(
                                  color: AppTheme.diffColor, fontSize: 12),
                            ),
                        ],
                      ),
              ),
              const Icon(Icons.expand_more, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  // 기종 선택 모달 (제조사별 그룹핑 + 검색)
  void _showPhonePicker() {
    final phoneProv =
        Provider.of<PhonePresetProvider>(context, listen: false);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      builder: (ctx) => _PhonePickerSheet(
        presets: phoneProv.presets,
        onSelected: (preset) {
          setState(() {
            _selectedPreset = preset;
            // 자급제 기본가 자동 채움
            if (preset.defaultJagupPrice != null &&
                _jagupPriceCtrl.text.isEmpty) {
              _jagupPriceCtrl.text =
                  preset.defaultJagupPrice.toString();
              _jagupAutoFilled = true;
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget? extraHeader,
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
                if (extraHeader != null) ...[
                  const Spacer(),
                  extraHeader,
                ],
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

  // 자급제 가격 필드 (자동 채움 라벨 포함)
  Widget _buildPriceFieldWithAuto({
    required TextEditingController controller,
    required String label,
    required bool isAutoFilled,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: label,
              suffixText: '원',
              helperText: isAutoFilled ? '기종 기본가에서 자동 채움' : null,
              helperStyle: const TextStyle(color: AppTheme.secondary, fontSize: 11),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {
              _jagupAutoFilled = false; // 수정하면 자동 라벨 제거
            }),
          ),
        ),
      ],
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
                  icon: const Icon(Icons.close,
                      size: 18, color: Colors.redAccent),
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
                            const SnackBar(
                                content: Text('월 요금을 입력해주세요.')),
                          );
                          return;
                        }
                        if (months == null ||
                            months < 1 ||
                            months > 24) {
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

// 기종 선택 바텀 시트
class _PhonePickerSheet extends StatefulWidget {
  final List<PhonePreset> presets;
  final ValueChanged<PhonePreset> onSelected;

  const _PhonePickerSheet({
    required this.presets,
    required this.onSelected,
  });

  @override
  State<_PhonePickerSheet> createState() => _PhonePickerSheetState();
}

class _PhonePickerSheetState extends State<_PhonePickerSheet> {
  String _query = '';

  List<PhonePreset> get _filtered {
    if (_query.isEmpty) return widget.presets;
    return widget.presets
        .where((p) =>
            p.name.toLowerCase().contains(_query.toLowerCase()) ||
            (p.manufacturer?.toLowerCase().contains(_query.toLowerCase()) ??
                false))
        .toList();
  }

  // 제조사별 그룹핑
  Map<String, List<PhonePreset>> _groupByMfr(List<PhonePreset> list) {
    final grouped = <String, List<PhonePreset>>{};
    for (final p in list) {
      final mfr = p.manufacturer ?? '기타';
      grouped.putIfAbsent(mfr, () => []).add(p);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    const groupOrder = ['삼성', '애플', '기타'];
    final grouped = _groupByMfr(_filtered);
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ia = groupOrder.indexOf(a);
        final ib = groupOrder.indexOf(b);
        final ra = ia == -1 ? 99 : ia;
        final rb = ib == -1 ? 99 : ib;
        return ra.compareTo(rb);
      });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Container(
          color: AppTheme.cardBg,
          child: Column(
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 검색창
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: '기종 검색...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              // 목록
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    for (final mfr in sortedKeys) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                        ListTile(
                          title: Text(preset.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: preset.releaseDate != null
                              ? Text(preset.releaseDate!,
                                  style: const TextStyle(
                                      color: AppTheme.diffColor,
                                      fontSize: 12))
                              : null,
                          trailing: preset.defaultJagupPrice != null
                              ? Text(
                                  '${_fmtNum(preset.defaultJagupPrice!)}원',
                                  style: const TextStyle(
                                      color: AppTheme.diffColor,
                                      fontSize: 12),
                                )
                              : null,
                          onTap: () => widget.onSelected(preset),
                        ),
                    ],
                    if (grouped.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            '검색 결과가 없습니다',
                            style: TextStyle(color: AppTheme.diffColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtNum(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
