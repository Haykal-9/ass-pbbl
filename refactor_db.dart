import 'dart:io';

void main() {
  final file = File('lib/services/database_helper.dart');
  var content = file.readAsStringSync();
  
  // 1. Remove 'oh': '...', 
  content = content.replaceAll(RegExp(r"'oh': '[^']+', "), "");

  // 2. Add 'et' based on 't'
  // We match 't': 'HH:MM'
  content = content.replaceAllMapped(RegExp(r"'t': '(\d{2}):(\d{2})'(?!, 'et')"), (match) {
    int h = int.parse(match.group(1)!);
    int m = int.parse(match.group(2)!);
    
    // Add 1 hour by default for dummy data
    int endH = (h + 1) % 24;
    String endT = '${endH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    
    return "'t': '${match.group(1)}:${match.group(2)}', 'et': '$endT'";
  });

  file.writeAsStringSync(content);
  print('Updated database_helper.dart successfully');
}
