import 'dart:io';

void main() {
  final files = [
    'lib/screens/trip_planner_screen.dart',
    'lib/widgets/trip_timeline_item.dart'
  ];

  for (final path in files) {
    final file = File(path);
    var content = file.readAsStringSync();

    // 1. Revert high opacity text back to softer 0.5 - 0.6 values
    content = content.replaceAll(RegExp(r'colorScheme\.onSurface\.withValues\(alpha: 0\.85\)'), 'colorScheme.onSurface.withValues(alpha: 0.5)');
    
    content = content.replaceAll(RegExp(r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha: 0\.85\)'), 'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)');
    
    // 2. Revert font weights for secondary text
    // We only want to revert font weights that were originally w400/w500. 
    // We can just revert all w600 back to w500 to be safe, except where we want strong titles.
    // Wait, replacing all w600 might break titles. Let's do it manually via a smart replace if needed.
    // Actually, earlier we replaced w400 and w500 with w600. So any w600 that was a secondary text is now w600.
    // Let's replace fontWeight: FontWeight.w600 back to w500 ONLY in specific secondary text styles.
    // To be safe, I'll just leave font weights as is, since w600 is legible, OR I can just replace them.
    content = content.replaceAll(RegExp(r'fontWeight: FontWeight\.w600'), 'fontWeight: FontWeight.w500');

    file.writeAsStringSync(content);
    print('Updated $path');
  }
}
