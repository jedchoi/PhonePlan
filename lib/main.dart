import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/addon_preset_provider.dart';
import 'providers/device_provider.dart';
import 'providers/discount_program_provider.dart';
import 'providers/price_preset_provider.dart';
import 'providers/user_profile_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // StorageService 초기화
  final storage = await StorageService.create();

  // Provider 인스턴스 생성 (SharedPreferences 데이터 로드)
  final discountProv = DiscountProgramProvider(storage);
  final priceProv = PricePresetProvider(storage);
  final addonProv = AddonPresetProvider(storage);
  final profileProv = UserProfileProvider(storage);
  final deviceProv = DeviceProvider(storage);

  // 앱 최초 실행 시 기본 프리셋 데이터 주입
  if (!storage.isInitialized) {
    await discountProv.initDefaults();
    await priceProv.initDefaults();
    await addonProv.initDefaults();
    await storage.setInitialized();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: discountProv),
        ChangeNotifierProvider.value(value: priceProv),
        ChangeNotifierProvider.value(value: addonProv),
        ChangeNotifierProvider.value(value: profileProv),
        ChangeNotifierProvider.value(value: deviceProv),
      ],
      child: const JagupApp(),
    ),
  );
}

class JagupApp extends StatelessWidget {
  const JagupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '자급제공시선약',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark, // 다크모드 전용 고정
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
