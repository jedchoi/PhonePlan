import 'package:flutter/material.dart';
import 'settings/discount_management_screen.dart';
import 'settings/price_management_screen.dart';
import 'settings/addon_management_screen.dart';
import '../theme/app_theme.dart';

// 탭4: 설정 화면 (마스터 데이터 관리)
class Tab4SettingsScreen extends StatelessWidget {
  const Tab4SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('마스터 데이터 관리'),
          _buildSettingsTile(
            context,
            icon: Icons.percent,
            title: '할인프로그램 관리',
            subtitle: '가족결합, 복지할인, 선택약정 등',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DiscountManagementScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.sim_card_outlined,
            title: '요금제 프리셋 관리',
            subtitle: '자주 사용하는 요금제 금액 등록',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PriceManagementScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.add_box_outlined,
            title: '부가서비스 프리셋 관리',
            subtitle: '넷플릭스, 디즈니플러스 등',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddonManagementScreen()),
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader('앱 정보'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.diffColor),
            title: const Text('버전',
                style: TextStyle(color: Colors.white70)),
            trailing: const Text('1.0.0',
                style: TextStyle(color: AppTheme.diffColor)),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined,
                color: AppTheme.diffColor),
            title: const Text('계산 기준',
                style: TextStyle(color: Colors.white70)),
            subtitle: const Text(
              '24개월 기준, 기기 현금 선납 (할부이자 없음)',
              style: TextStyle(color: AppTheme.diffColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: AppTheme.diffColor)),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.diffColor),
      onTap: onTap,
    );
  }
}
