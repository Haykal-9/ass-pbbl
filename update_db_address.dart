import 'dart:io';

void main() {
  final file = File('lib/services/database_helper.dart');
  var content = file.readAsStringSync();
  
  // Add place_address and opening_hours
  content = content.replaceAll(
    "'place_name': s['n'], 'latitude': s['la'], 'longitude': s['lo'],",
    "'place_name': s['n'], 'place_address': s['a'], 'opening_hours': s['oh'], 'latitude': s['la'], 'longitude': s['lo'],"
  );
  
  // Update Borobudur Basecamp (The Omah Borobudur)
  content = content.replaceAll(
    "{'n': 'The Omah Borobudur', 'la': -7.6085, 'lo': 110.1985, 't': '05:00', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'}",
    "{'n': 'The Omah Borobudur', 'a': 'Jl. Syailendra Raya, Borobudur, Magelang, Jawa Tengah 56553', 'oh': 'Check-in: 14:00 - Check-out: 12:00', 'la': -7.6085, 'lo': 110.1985, 't': '05:00', 'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'}"
  );

  file.writeAsStringSync(content);
  print('Updated database_helper.dart with address and opening hours');
}
