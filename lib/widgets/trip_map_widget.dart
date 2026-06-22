import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_stop.dart';
import '../services/openrouteservice_service.dart';

class TripMapWidget extends StatefulWidget {
  final List<TripStop> stops;
  final TripStop? highlightedStop;
  final ValueChanged<TripStop>? onStopTapped;

  const TripMapWidget({
    super.key,
    required this.stops,
    this.highlightedStop,
    this.onStopTapped,
  });

  @override
  State<TripMapWidget> createState() => _TripMapWidgetState();
}

class _TripMapWidgetState extends State<TripMapWidget> {
  final MapController _mapController = MapController();
  final OpenRouteService _orsService = OpenRouteService();
  
  // Cache routes to avoid spamming the API when switching tabs.
  // Key: day number (or unique ID of stops), Value: List of route points
  static final Map<String, List<LatLng>> _routeCache = {};
  
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(TripMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stops != oldWidget.stops) {
      _fetchRoute();
    }
    if (widget.stops != oldWidget.stops || widget.highlightedStop != oldWidget.highlightedStop) {
      _fitBounds();
    }
  }

  Future<void> _fetchRoute() async {
    final validStops = widget.stops.where((s) => s.latitude != null && s.longitude != null).toList();
    if (validStops.length < 2) {
      setState(() => _routePoints = []);
      return;
    }

    validStops.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    
    // Generate a simple cache key based on stop IDs/coordinates
    final cacheKey = validStops.map((s) => '${s.latitude},${s.longitude}').join('|');
    
    if (_routeCache.containsKey(cacheKey)) {
      setState(() {
        _routePoints = _routeCache[cacheKey]!;
      });
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final waypoints = validStops.map((s) => LatLng(s.latitude!, s.longitude!)).toList();
      final route = await _orsService.getRoute(waypoints);
      
      _routeCache[cacheKey] = route;
      
      if (mounted) {
        setState(() => _routePoints = route);
      }
    } catch (e) {
      // Fallback to straight lines
      if (mounted) {
        setState(() {
          _routePoints = validStops.map((s) => LatLng(s.latitude!, s.longitude!)).toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _fitBounds() {
    if (widget.stops.isEmpty) return;
    
    if (widget.highlightedStop != null && widget.highlightedStop?.latitude != null && widget.highlightedStop?.longitude != null) {
      _mapController.move(
        LatLng(widget.highlightedStop!.latitude!, widget.highlightedStop!.longitude!),
        15.0,
      );
      return;
    }

    final validStops = widget.stops.where((s) => s.latitude != null && s.longitude != null).toList();
    if (validStops.isEmpty) return;

    if (validStops.length == 1) {
      _mapController.move(LatLng(validStops.first.latitude!, validStops.first.longitude!), 13.0);
      return;
    }

    double minLat = validStops.first.latitude!;
    double maxLat = validStops.first.latitude!;
    double minLng = validStops.first.longitude!;
    double maxLng = validStops.first.longitude!;

    for (var s in validStops) {
      if (s.latitude! < minLat) minLat = s.latitude!;
      if (s.latitude! > maxLat) maxLat = s.latitude!;
      if (s.longitude! < minLng) minLng = s.longitude!;
      if (s.longitude! > maxLng) maxLng = s.longitude!;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
  }

  @override
  Widget build(BuildContext context) {
    final validStops = widget.stops.where((s) => s.latitude != null && s.longitude != null).toList();
    validStops.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final pinPoints = validStops.map((s) => LatLng(s.latitude!, s.longitude!)).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: pinPoints.isNotEmpty ? pinPoints.first : const LatLng(0, 0),
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onMapReady: _fitBounds,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.wanderlist',
            ),
            if (_routePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 4.0,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF2C3E50) // Navy-grey blend
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            MarkerLayer(
              markers: validStops.asMap().entries.map((entry) {
                final idx = entry.key;
                final stop = entry.value;
                final isHighlighted = widget.highlightedStop?.id == stop.id;
                
                return Marker(
                  point: LatLng(stop.latitude!, stop.longitude!),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => widget.onStopTapped?.call(stop),
                    child: CustomPaint(
                      painter: NumberedMarkerPainter(
                        number: stop.isBasecamp ? 0 : idx + (validStops.isNotEmpty && validStops.first.isBasecamp ? 0 : 1),
                        color: stop.isBasecamp 
                            ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34495E) : Colors.blueGrey.shade800)
                            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C3E50) : Theme.of(context).colorScheme.primary),
                        isHighlighted: isHighlighted,
                        isBasecamp: stop.isBasecamp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (_isLoadingRoute)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
      ],
    );
  }
}

class NumberedMarkerPainter extends CustomPainter {
  final int number;
  final Color color;
  final bool isHighlighted;
  final bool isBasecamp;

  NumberedMarkerPainter({
    required this.number,
    required this.color,
    required this.isHighlighted,
    this.isBasecamp = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);

    // Highlight ring
    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 4, highlightPaint);
    }

    // Main circle
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    if (isBasecamp) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.home.codePoint),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: Icons.home.fontFamily,
            package: Icons.home.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    } else {
      final textPainter = TextPainter(
        text: TextSpan(
          text: number.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant NumberedMarkerPainter oldDelegate) {
    return oldDelegate.number != number ||
           oldDelegate.color != color ||
           oldDelegate.isHighlighted != isHighlighted;
  }
}
