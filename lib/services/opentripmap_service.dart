import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_constants.dart';

class OpenTripMapService {
  static const String baseUrl = 'https://api.opentripmap.com/0.1/en/places';

  Future<List<Map<String, dynamic>>> searchPlaces(String query, {int limit = 10}) async {
    try {
      final url = Uri.parse('$baseUrl/geoname?name=$query&apikey=${ApiConstants.openTripMapKey}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['error'] != null) return [];
        // OTM geoname API returns an object for the closest match or a list? 
        // Wait, actually /geoname returns a single feature or a list of places. 
        // Let's use the autosuggest API instead which is better for autocomplete.
        final suggestUrl = Uri.parse('$baseUrl/autosuggest?name=$query&radius=10000000&lon=0&lat=0&format=json&apikey=${ApiConstants.openTripMapKey}');
        final suggestRes = await http.get(suggestUrl).timeout(const Duration(seconds: 10));
        
        if (suggestRes.statusCode == 200) {
          final List<dynamic> list = jsonDecode(suggestRes.body);
          return list.map((e) => e as Map<String, dynamic>).toList();
        }
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

  Future<Map<String, dynamic>> getPlaceDetails(String xid) async {
    try {
      final url = Uri.parse('$baseUrl/xid/$xid?apikey=${ApiConstants.openTripMapKey}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Koneksi bermasalah, coba lagi');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Gagal mengambil detail: $e');
    }
  }
}
