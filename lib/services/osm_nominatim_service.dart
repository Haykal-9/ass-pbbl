import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class OsmNominatimService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<Map<String, dynamic>>> searchPlaces(String query, {int limit = 10}) async {
    try {
      // Nominatim requires a user-agent to avoid being blocked
      final url = Uri.parse('$baseUrl?q=$query&format=json&addressdetails=1&limit=$limit');
      final response = await http.get(url, headers: {
        'User-Agent': 'WanderlistApp/1.0 (Student Project)',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } on TimeoutException {
      throw Exception('Koneksi bermasalah, coba lagi');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Gagal mencari tempat: $e');
    }
  }

  // Nominatim search already returns lat/lon and address, so we don't need a separate details call
  // But we simulate it or just parse the result directly.
  Future<Map<String, dynamic>> getPlaceDetails(Map<String, dynamic> place) async {
    // Return formatted data for UI
    final address = place['address'] ?? {};
    final road = address['road'] ?? '';
    final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
    final country = address['country'] ?? '';
    
    final fullAddr = [road, city, country].where((e) => e.toString().isNotEmpty).join(', ');
    
    return {
      'name': place['name']?.toString().isNotEmpty == true ? place['name'] : place['display_name']?.split(',').first,
      'address_str': fullAddr.isNotEmpty ? fullAddr : place['display_name'],
      'lat': double.tryParse(place['lat'] ?? ''),
      'lng': double.tryParse(place['lon'] ?? ''),
      'xid': place['place_id']?.toString(), // Use OSM place_id as xid
    };
  }
}
