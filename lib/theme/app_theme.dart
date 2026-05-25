import 'package:flutter/material.dart';

// 앱 전체 다크 테마 정의
class AppTheme {
  // 주요 색상
  static const Color primary = Color(0xFF4FC3F7); // 밝은 시안
  static const Color secondary = Color(0xFFFFB74D); // 오렌지
  static const Color cheapest = Color(0xFF4CAF50); // 최저가 강조 그린
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color scaffoldBg = Color(0xFF121212);
  static const Color diffColor = Color(0xFF9E9E9E); // 차액 표시 그레이
  static const Color seonyakBadge = Color(0xFF7986CB); // 선택약정 뱃지 색상

  static ThemeData get dark => ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: cardBg,
        ),
        scaffoldBackgroundColor: scaffoldBg,
        cardColor: cardBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: primary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: primary,
          unselectedItemColor: Color(0xFF757575),
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: cardBg,
          selectedColor: primary.withAlpha(51),
          labelStyle: const TextStyle(color: Colors.white),
          side: const BorderSide(color: Color(0xFF424242)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF424242)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primary),
          ),
          labelStyle: const TextStyle(color: Color(0xFFBDBDBD)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.black87,
        ),
        dividerColor: const Color(0xFF2C2C2C),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.black87),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return primary.withAlpha(128);
            }
            return Colors.grey.withAlpha(128);
          }),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: primary,
          thumbColor: primary,
          inactiveTrackColor: Color(0xFF424242),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
          bodySmall: TextStyle(color: Color(0xFF9E9E9E)),
        ),
      );
}
