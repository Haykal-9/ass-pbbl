import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_locale.dart';
import 'services/currency_service.dart';
import 'services/preferences_service.dart';

final ValueNotifier<String> themeNotifier = ValueNotifier('Canopy');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  Color _seedColor(String temaWarna) {
    switch (temaWarna) {
      case 'Ancient Earth':
        return const Color(0xFF8B5E3C);
      case 'Urban Slate':
        return const Color(0xFF3D4451);
      case 'Canopy':
      default:
        return const Color(0xFF3A6B4A);
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
                  theme: ThemeData(
                    colorScheme:
                        ColorScheme.fromSeed(seedColor: _seedColor(temaWarna)),
                    useMaterial3: true,
                  ),
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
