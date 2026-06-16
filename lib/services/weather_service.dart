import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'api_constants.dart';

class WeatherService {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  Future<Map<String, dynamic>?> getForecastForDate(double lat, double lng, DateTime targetDate) async {
    try {
      final url = Uri.parse('$baseUrl?lat=$lat&lon=$lng&appid=${ApiConstants.openWeatherMapKey}&units=metric&lang=id');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['list'];
        
        // Find the forecast closest to 12:00 PM on the target date
        Map<String, dynamic>? bestMatch;
        double minDiff = double.infinity;

        for (var item in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          if (dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day) {
            final diff = (dt.hour - 12).abs().toDouble();
            if (diff < minDiff) {
              minDiff = diff;
              bestMatch = item;
            }
          }
        }
        
        return bestMatch; // Can be null if date is outside 5-day forecast
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Koneksi bermasalah, coba lagi');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } catch (e) {
      throw Exception('Gagal mengambil cuaca: $e');
    }
  }

  static String weatherIconPath(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '⛅';
      case 'rain': return '🌧️';
      case 'drizzle': return '🌦️';
      case 'thunderstorm': return '⛈️';
      case 'snow': return '❄️';
      default: return '☁️';
    }
  }
}
