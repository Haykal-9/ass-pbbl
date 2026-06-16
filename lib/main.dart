import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'services/app_locale.dart';
import 'services/currency_service.dart';
import 'services/preferences_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

final ValueNotifier<String> themeNotifier = ValueNotifier('Canopy');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = PreferencesService();
  final temaWarna = await prefs.getTemaWarna();
  final bahasa = await prefs.getBahasa();
  final mataUang = await prefs.getMataUang();
  themeNotifier.value = temaWarna;
  bahasaNotifier.value = bahasa;
  currencyNotifier.value = mataUang;
  runApp(const WanderListApp());
}

class WanderListApp extends StatelessWidget {
  const WanderListApp({super.key});

  ThemeData _buildTheme(String temaWarna) {
    switch (temaWarna) {
      case 'Ancient Earth':
        final colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C),
          brightness: Brightness.light,
        ).copyWith(
          onPrimary: Colors.white,
        );
        return ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFFFDF5E6),
          cardColor: const Color(0xFFFFFBF0),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFDF5E6),
            foregroundColor: Color(0xFF3E2723),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFFFBF0),
          ),
        );
      case 'Urban Slate':
        final colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF607D8B),
          brightness: Brightness.dark,
        ).copyWith(
          onPrimary: const Color(0xFF0B192C), // Navy/Dark color for better contrast
        );
        return ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFF1E2329),
          cardColor: const Color(0xFF282C34),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E2329),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF282C34),
          ),
        );
      case 'Canopy':
      default:
        final colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A6B4A),
          brightness: Brightness.light,
        ).copyWith(
          onPrimary: Colors.white,
        );
        return ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFFF1F8F4),
          cardColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF1F8F4),
            foregroundColor: Color(0xFF1B3D26),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: themeNotifier,
      builder: (context, temaWarna, _) {
        return ValueListenableBuilder<String>(
          valueListenable: bahasaNotifier,
          builder: (context, bahasa, _) {
            return ValueListenableBuilder<String>(
              valueListenable: currencyNotifier,
              builder: (context, mataUang, _) {
                return MaterialApp(
                  title: 'WanderList',
                  debugShowCheckedModeBanner: false,
                  theme: _buildTheme(temaWarna),
                  scrollBehavior: AppScrollBehavior(),
                  home: const HomeScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}
