import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/device_provider.dart';
import '../providers/discount_program_provider.dart';
import '../providers/user_profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/device_summary_card.dart';
import 'tab2_device_edit_screen.dart';

// 탭2: 기기 비교 목록 화면
class Tab2DevicesScreen extends StatelessWidget {
  const Tab2DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기기 비교')),
      body: Consumer3<DeviceProvider, UserProfileProvider,
          DiscountProgramProvider>(
        builder: (context, deviceProv, profileProv, discountProv, _) {
          final devices = deviceProv.devices;
          if (devices.isEmpty) {
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final comparison =
                  deviceProv.compare(device, profile, programs);
              return DeviceSummaryCard(
                device: device,
                comparison: comparison,
                onTap: () => _openEdit(context, device),
                onLongPress: () => _confirmDelete(context, deviceProv, device),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        child: const Icon(Icons.add),
      ),
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

  void _openEdit(BuildContext context, Device device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Tab2DeviceEditScreen(device: device),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, DeviceProvider prov, Device device) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('기기 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
          '${device.name}을(를) 삭제하시겠습니까?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              prov.remove(device.id);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
