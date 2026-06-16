import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get openWeatherMapKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
}
