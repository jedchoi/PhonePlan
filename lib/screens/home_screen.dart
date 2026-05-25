import 'package:flutter/material.dart';
import 'tab1_my_info_screen.dart';
import 'tab2_devices_screen.dart';
import 'tab3_results_screen.dart';
import 'tab4_settings_screen.dart';

// 4개 탭을 가진 메인 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Tab1MyInfoScreen(),
    Tab2DevicesScreen(),
    Tab3ResultsScreen(),
    Tab4SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '내 정보'),
          BottomNavigationBarItem(icon: Icon(Icons.smartphone), label: '기기 비교'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: '비교 결과'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
