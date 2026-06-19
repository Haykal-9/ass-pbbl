import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get openWeatherMapKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static String get openTripMapKey => dotenv.env['OPENTRIPMAP_API_KEY'] ?? '';
}
