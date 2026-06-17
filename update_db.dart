import 'dart:io';

void main() {
  final file = File('lib/services/database_helper.dart');
  var content = file.readAsStringSync();
  
  // Add generic photo to basecamps
  content = content.replaceAll(
    "'bc': 1}", 
    "'bc': 1, 'p': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=600'}"
  );

  // Fix Candi Borobudur coordinates
  content = content.replaceAll(
    "{'n': 'Candi Borobudur', 'la': -7.6079, 'lo': 110.2038",
    "{'n': 'Candi Borobudur', 'la': -7.6076, 'lo': 110.2058"
  );
  
  // Fix Omah Borobudur coordinates slightly to the main road
  content = content.replaceAll(
    "{'n': 'The Omah Borobudur', 'la': -7.6080, 'lo': 110.1980",
    "{'n': 'The Omah Borobudur', 'la': -7.6085, 'lo': 110.1985"
  );

  file.writeAsStringSync(content);
  print('Updated database_helper.dart successfully');
}
