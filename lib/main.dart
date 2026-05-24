import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final temaWarna = await PreferencesService().getTemaWarna();
  runApp(WanderListApp(temaWarna: temaWarna));
}

class WanderListApp extends StatelessWidget {
  final String temaWarna;

  const WanderListApp({super.key, required this.temaWarna});

  Color _seedColor() {
    switch (temaWarna) {
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WanderList',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor()),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
