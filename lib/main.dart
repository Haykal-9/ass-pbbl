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
  try {
    await dotenv.load(fileName: ".env");
  } catch (error) {
    debugPrint('Skipping .env load: $error');
  }
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
          seedColor: const Color(0xFFB07D62), // Terracotta clay
          brightness: Brightness.light,
        ).copyWith(
          onPrimary: Colors.white,
        );
        return ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFFFCF8F2), // Warm sand
          cardColor: Colors.white,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFCF8F2),
            foregroundColor: Color(0xFF4A3B32),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
          ),
        );
      case 'Urban Slate':
        final colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF7CA1C0), // Calm dusty blue
          brightness: Brightness.dark,
        ).copyWith(
          onPrimary: const Color(0xFF15191E), 
        );
        return ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFF15191E), // Deep slate navy
          cardColor: const Color(0xFF222831), // Soft dark greyish blue
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF15191E),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF222831),
          ),
        );
      case 'Canopy':
      default:
        final colorScheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E8B57), // Sea green
          brightness: Brightness.light,
        ).copyWith(
          onPrimary: Colors.white,
        );
        return ThemeData(
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFFF4F9F6), // Very soft mint
          cardColor: Colors.white, 
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4F9F6),
            foregroundColor: Color(0xFF1E3A2B),
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
