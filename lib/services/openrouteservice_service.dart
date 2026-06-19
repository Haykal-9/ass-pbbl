import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouteService {
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';

  Future<List<LatLng>> getRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final apiKey = dotenv.env['ORS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ORS_API_KEY is missing in .env');
    }

    final coordinates = waypoints.map((p) => [p.longitude, p.latitude]).toList();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
        },
        body: jsonEncode({
          'coordinates': coordinates,
          'instructions': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final geometry = data['features'][0]['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final List coords = geometry['coordinates'];
            final List<LatLng> polyline = [waypoints.first];
            polyline.addAll(coords.map((c) => LatLng(c[1] as double, c[0] as double)));
            polyline.add(waypoints.last);
            return polyline;
          }
        }
      }
      return waypoints; // Fallback to straight lines if API fails
    } catch (e) {
      return waypoints; // Fallback
    }
  }

  Future<Map<String, dynamic>?> getDistanceAndDuration(LatLng start, LatLng end, String transportMode) async {
    final apiKey = dotenv.env['ORS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    String profile = 'driving-car';
    if (transportMode == 'bike') profile = 'cycling-regular';
    if (transportMode == 'walk') profile = 'foot-walking';

    final url = 'https://api.openrouteservice.org/v2/directions/$profile/geojson';
    final coordinates = [
      [start.longitude, start.latitude],
      [end.longitude, end.latitude]
    ];

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
        },
        body: jsonEncode({
          'coordinates': coordinates,
          'instructions': false,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final properties = data['features'][0]['properties'];
          if (properties != null && properties['segments'] != null && properties['segments'].isNotEmpty) {
            final segment = properties['segments'][0];
            return {
              'distance': (segment['distance'] as num).toDouble(), // in meters
              'duration': (segment['duration'] as num).toDouble(), // in seconds
            };
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
