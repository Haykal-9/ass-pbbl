import 'dart:io';

void main() {
  final file = File('lib/services/database_helper.dart');
  var content = file.readAsStringSync();

  final regex = RegExp(r"\{'n':\s*'([^']+)',\s*(?:'a':\s*'[^']+',\s*)?(?:'oh':\s*'[^']+',\s*)?'la':");

  final newContent = content.replaceAllMapped(regex, (match) {
    final name = match.group(1)!;
    String address = 'Address of ' + name;
    String hours = '08:00 - 17:00';

    if (name.contains('Hotel') || name.contains('Inn') || name.contains('Resort') || name.contains('Basecamp') || name.contains('Sheraton') || name.contains('Sands') || name.contains('Raffles') || name.contains('Lodge') || name.contains('Marriott')) {
      hours = 'Check-in: 14:00 - Check-out: 12:00';
    } else if (name.contains('Times Square') || name.contains('Shibuya')) {
      hours = '24 Jam';
    }

    // Specific mapping
    if (name == 'The Omah Borobudur') {
      address = 'Jl. Syailendra Raya, Borobudur, Magelang, Jawa Tengah 56553';
      hours = 'Check-in: 14:00 - Check-out: 12:00';
    } else if (name == 'Candi Borobudur') {
      address = 'Jl. Badrawati, Kw. Candi Borobudur, Borobudur, Magelang';
      hours = '06:00 - 17:00';
    } else if (name == 'Candi Pawon') {
      address = 'Brojonalan, Dusun 1, Wanurejo, Borobudur, Magelang';
      hours = '08:00 - 16:00';
    } else if (name == 'Candi Mendut') {
      address = 'Jl. Mayor Kusen, Sumberrejo, Mendut, Mungkid, Magelang';
      hours = '07:00 - 17:30';
    } else if (name == 'Meridian Adventure Marina') {
      address = 'Waisai, Raja Ampat Regency, West Papua';
    } else if (name == 'Pianemo Islands') {
      address = 'Groot Fam, Saukabu, Raja Ampat Regency';
      hours = '08:00 - 18:00';
    } else if (name == 'Wayag Lagoon') {
      address = 'Waigeo Barat Kepulauan, Raja Ampat';
      hours = '24 Jam';
    } else if (name == 'Arborek Village') {
      address = 'Arborek, Meos Mansar, Raja Ampat';
      hours = '24 Jam';
    } else if (name == 'Ayana Komodo Resort') {
      address = 'Pantai Waecicu, Labuan Bajo, Kabupaten Manggarai Barat';
    } else if (name == 'Pulau Padar') {
      address = 'Taman Nasional Komodo, Kabupaten Manggarai Barat';
      hours = '06:00 - 18:00';
    } else if (name == 'Pink Beach') {
      address = 'Pulau Komodo, Kabupaten Manggarai Barat';
      hours = '08:00 - 17:00';
    } else if (name == 'Manta Point') {
      address = 'Perairan Komodo, Manggarai Barat';
      hours = '08:00 - 15:00';
    } else if (name == 'Hoshinoya Fuji') {
      address = '1408 Oishi, Fujikawaguchiko, Minamitsuru District, Yamanashi';
    } else if (name == 'Lake Kawaguchi') {
      address = 'Fujikawaguchiko, Minamitsuru District, Yamanashi';
      hours = '24 Jam';
    } else if (name == 'Chureito Pagoda') {
      address = '3353-1 Arakura, Fujiyoshida, Yamanashi';
      hours = '24 Jam';
    } else if (name == 'Fuji 5th Station') {
      address = 'Naruzawa, Minamitsuru District, Yamanashi';
      hours = '09:00 - 17:00';
    } else if (name == 'Sheraton Fallsview') {
      address = '5875 Falls Ave, Niagara Falls, ON';
    } else if (name == 'Horseshoe Falls') {
      address = 'Niagara Falls, ON L2G 0L0';
      hours = '24 Jam';
    } else if (name == 'Maid of the Mist') {
      address = '1 Prospect St, Niagara Falls, NY';
      hours = '09:00 - 17:00';
    } else if (name == 'Skylon Tower') {
      address = '5200 Robinson St, Niagara Falls, ON';
      hours = '10:00 - 22:00';
    } else if (name == 'Old Faithful Inn') {
      address = '3200 Old Faithful Inn Rd, Yellowstone National Park, WY';
    } else if (name == 'Old Faithful Geyser') {
      address = 'Yellowstone National Park, WY 82190';
      hours = '24 Jam';
    } else if (name == 'Grand Prismatic Spring') {
      address = 'Midway Geyser Basin, Yellowstone National Park, WY';
      hours = '06:00 - 18:00';
    } else if (name == 'Yellowstone Lake') {
      address = 'Yellowstone National Park, WY';
      hours = '24 Jam';
    } else if (name == 'Raffles Grand Hotel') {
      address = '1 Vithei, Charles De Gaulle, Krong Siem Reap';
    } else if (name == 'Angkor Wat') {
      address = 'Krong Siem Reap, Cambodia';
      hours = '05:00 - 17:30';
    } else if (name == 'Bayon Temple') {
      address = 'Angkor Thom, Siem Reap';
      hours = '07:30 - 17:30';
    } else if (name == 'Ta Prohm') {
      address = 'Angkor Archaeological Park, Siem Reap';
      hours = '07:30 - 17:30';
    } else if (name == 'Hotel Artemide') {
      address = 'Via Nazionale, 22, 00184 Roma RM, Italy';
    } else if (name == 'Colosseum') {
      address = 'Piazza del Colosseo, 1, 00184 Roma RM, Italy';
      hours = '08:30 - 19:00';
    } else if (name == 'Roman Forum') {
      address = 'Via della Salara Vecchia, 5/6, 00186 Roma RM';
      hours = '09:00 - 19:00';
    } else if (name == 'Pantheon') {
      address = 'Piazza della Rotonda, 00186 Roma RM, Italy';
      hours = '09:00 - 19:00';
    } else if (name == 'Sanctuary Lodge') {
      address = 'Carretera Hiram Bingham Km 7.5, Machu Picchu';
    } else if (name == 'Machu Picchu Ruins') {
      address = 'Machu Picchu 08680, Peru';
      hours = '06:00 - 17:30';
    } else if (name == 'Huayna Picchu') {
      address = 'Machu Picchu 08680, Peru';
      hours = '07:00 - 14:00';
    } else if (name == 'Sun Gate (Inti Punku)') {
      address = 'Inca Trail, Machu Picchu 08680';
      hours = '06:00 - 16:00';
    } else if (name == 'The Peninsula Beijing') {
      address = '8 Goldfish Ln, Dongcheng, Beijing';
    } else if (name == 'Mutianyu Great Wall') {
      address = 'Mutianyu Rd, Huairou District, Beijing';
      hours = '07:30 - 17:30';
    } else if (name == 'Jiankou') {
      address = 'Huairou District, Beijing';
      hours = '24 Jam';
    } else if (name == 'Forbidden City') {
      address = '4 Jingshan Front St, Dongcheng, Beijing';
      hours = '08:30 - 17:00';
    } else if (name == 'Armani Hotel Dubai') {
      address = 'Burj Khalifa, Downtown Dubai, Dubai';
    } else if (name == 'Burj Khalifa At The Top') {
      address = '1 Sheikh Mohammed bin Rashid Blvd, Downtown Dubai';
      hours = '08:00 - 23:00';
    } else if (name == 'Dubai Mall') {
      address = 'Downtown Dubai, Dubai';
      hours = '10:00 - 00:00';
    } else if (name == 'Dubai Fountain') {
      address = 'Sheikh Mohammed bin Rashid Blvd, Downtown Dubai';
      hours = '18:00 - 23:00';
    } else if (name == 'Pullman Paris Tour Eiffel') {
      address = '18 Avenue De Suffren, 75015 Paris';
    } else if (name == 'Eiffel Tower') {
      address = 'Champ de Mars, 5 Av. Anatole France, 75007 Paris';
      hours = '09:30 - 23:45';
    } else if (name == 'Seine River Cruise') {
      address = 'Port de la Bourdonnais, 75007 Paris';
      hours = '10:00 - 22:30';
    } else if (name == 'Louvre Museum') {
      address = 'Rue de Rivoli, 75001 Paris, France';
      hours = '09:00 - 18:00';
    } else if (name == 'Shibuya Excel Hotel Tokyu') {
      address = '1-12-2 Dogenzaka, Shibuya City, Tokyo';
    } else if (name == 'Shibuya Crossing') {
      address = 'Dogenzaka, Shibuya City, Tokyo 150-0043';
      hours = '24 Jam';
    } else if (name == 'Hachiko Memorial Statue') {
      address = '2-1 Dogenzaka, Shibuya City, Tokyo';
      hours = '24 Jam';
    } else if (name == 'Meiji Jingu') {
      address = '1-1 Yoyogikamizonocho, Shibuya City, Tokyo';
      hours = '05:00 - 18:00';
    } else if (name == 'Marina Bay Sands Hotel') {
      address = '10 Bayfront Ave, Singapore 018956';
    } else if (name == 'Gardens by the Bay') {
      address = '18 Marina Gardens Dr, Singapore 018953';
      hours = '05:00 - 02:00';
    } else if (name == 'ArtScience Museum') {
      address = '6 Bayfront Ave, Singapore 018974';
      hours = '10:00 - 19:00';
    } else if (name == 'Merlion Park') {
      address = '1 Fullerton Rd, Singapore 049213';
      hours = '24 Jam';
    } else if (name == 'New York Marriott Marquis') {
      address = '1535 Broadway, New York, NY 10036';
    } else if (name == 'Times Square') {
      address = 'Manhattan, NY 10036';
      hours = '24 Jam';
    } else if (name == 'Broadway Show') {
      address = 'Theater District, New York, NY';
      hours = '19:00 - 22:00';
    } else if (name == 'Central Park') {
      address = 'New York, NY';
      hours = '06:00 - 01:00';
    } else {
      address = name + ', Area';
    }

    // Replace single quotes just in case
    address = address.replaceAll("'", "\\'");
    
    // Use string concatenation to ensure literal values
    return "{'n': '" + name + "', 'a': '" + address + "', 'oh': '" + hours + "', 'la':";
  });

  file.writeAsStringSync(newContent);
  print('Successfully updated all 15 destinations with actual addresses and hours using concatenation.');
}
