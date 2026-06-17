import 'dart:io';

void main() {
  final files = [
    'lib/screens/trip_planner_screen.dart',
    'lib/widgets/trip_timeline_item.dart'
  ];

  for (final path in files) {
    final file = File(path);
    var content = file.readAsStringSync();

    // 1. Replace all low text opacities (alpha: 0.2/0.3/0.4/0.5/0.6) -> alpha: 0.8 or 0.9 if it's onSurface
    content = content.replaceAll(RegExp(r'colorScheme\.onSurface\.withValues\(alpha: 0\.[23456]\)'), 'colorScheme.onSurface.withValues(alpha: 0.85)');
    
    // 2. Also replace Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.X)
    content = content.replaceAll(RegExp(r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha: 0\.[23456]\)'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85)');
    
    // 3. Upgrade font weights for secondary text
    content = content.replaceAll(RegExp(r'fontWeight: FontWeight\.w[45]00'), 'fontWeight: FontWeight.w600');

    file.writeAsStringSync(content);
    print('Updated $path');
  }
}
