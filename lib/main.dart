import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'models/device.dart';
import 'models/device_offer.dart';
import 'models/phone_preset.dart';
import 'providers/addon_preset_provider.dart';
import 'providers/device_provider.dart';
import 'providers/discount_program_provider.dart';
import 'providers/phone_preset_provider.dart';
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
  final phonePresetProv = PhonePresetProvider(storage);
  final deviceProv = DeviceProvider(storage);

  // 앱 최초 실행 시 기본 프리셋 데이터 주입
  if (!storage.isInitialized) {
    await discountProv.initDefaults();
    await priceProv.initDefaults();
    await addonProv.initDefaults();
    await phonePresetProv.initDefaults();
    await storage.setInitialized();
  }

  // 구버전 Device 데이터 마이그레이션 (devices → phone_presets + device_offers)
  final oldDevicesJson = storage.loadOldDevices();
  if (oldDevicesJson.isNotEmpty) {
    for (final deviceJson in oldDevicesJson) {
      // PhonePreset 생성
      final presetId = const Uuid().v4();
      final jagupPriceRaw = deviceJson['jagupPrice'] as int;
      final preset = PhonePreset(
        id: presetId,
        name: deviceJson['name'] as String,
        manufacturer: '기타',
        defaultJagupPrice: jagupPriceRaw > 0 ? jagupPriceRaw : null,
      );
      await phonePresetProv.addPresetDirect(preset);

      // DeviceOffer 생성
      final offer = DeviceOffer(
        id: deviceJson['id'] as String,
        phonePresetId: presetId,
        storeName: '기본 매장',
        jagupPrice: jagupPriceRaw,
        seonyakPrice: deviceJson['seonyakPrice'] as int,
        seonyakRequiredPlan: deviceJson['seonyakRequiredPlan'] as int,
        seonyakRequiredMonths: deviceJson['seonyakRequiredMonths'] as int,
        seonyakAddons: (deviceJson['seonyakAddons'] as List)
            .map((e) => RequiredAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
        gongsiPrice: deviceJson['gongsiPrice'] as int,
        gongsiRequiredPlan: deviceJson['gongsiRequiredPlan'] as int,
        gongsiRequiredMonths: deviceJson['gongsiRequiredMonths'] as int,
        gongsiAddons: (deviceJson['gongsiAddons'] as List)
            .map((e) => RequiredAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      await deviceProv.addOfferDirect(offer);
    }
    await storage.clearOldDevices();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: discountProv),
        ChangeNotifierProvider.value(value: priceProv),
        ChangeNotifierProvider.value(value: addonProv),
        ChangeNotifierProvider.value(value: profileProv),
        ChangeNotifierProvider.value(value: phonePresetProv),
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
