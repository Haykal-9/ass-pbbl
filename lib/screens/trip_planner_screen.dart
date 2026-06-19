// PERSON C — Trip Planner (Rencana Perjalanan)

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/destination.dart';
import '../models/trip_stop.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/trip_timeline_item.dart';
import '../widgets/add_stop_sheet.dart';
import '../widgets/trip_map_widget.dart';
import '../services/weather_service.dart';
import '../services/openrouteservice_service.dart';
import 'package:intl/intl.dart';

class TripPlannerScreen extends StatefulWidget {
  final Destination destination;

  const TripPlannerScreen({super.key, required this.destination});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  late Destination _destination;

  List<TripStop> _allStops = [];
  int _selectedDay = 1;
  int _maxDay = 1;
  bool _isLoading = true;

  late TabController _tabController;
  final WeatherService _weatherService = WeatherService();
  final Map<int, Map<String, dynamic>?> _weatherForecast = {};

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _tabController = TabController(length: 1, vsync: this);
    _loadStops();
  }

  Future<void> _fetchWeather() async {
    if (_destination.latitude == null || _destination.longitude == null || _destination.startDate == null) return;
    try {
      final start = DateTime.parse(_destination.startDate!);
      for (int i = 1; i <= _maxDay; i++) {
        final targetDate = start.add(Duration(days: i - 1));
        final weather = await _weatherService.getForecastForDate(_destination.latitude!, _destination.longitude!, targetDate);
        if (mounted) {
          setState(() {
            _weatherForecast[i] = weather;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStops() async {
    try {
      final stops = await _db.getTripStops(_destination.id!);
      final maxDay = await _db.getMaxDayNumber(_destination.id!);

      if (mounted) {
        int newMaxDay = math.max(1, maxDay);
        if (_destination.tripDays > 0) {
          // Jika trip memiliki durasi spesifik, tab hari harus sesuai durasi tersebut
          newMaxDay = _destination.tripDays;
        }
        final clampedDay = _selectedDay.clamp(1, newMaxDay);

        _tabController.dispose();
        _tabController = TabController(
          length: newMaxDay,
          vsync: this,
          initialIndex: clampedDay - 1,
        );
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            setState(() => _selectedDay = _tabController.index + 1);
          }
        });

        setState(() {
          _allStops = stops;
          _maxDay = newMaxDay;
          _selectedDay = clampedDay;
          _isLoading = false;
        });
        _fetchWeather();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(context, 'Gagal memuat rencana: $e');
      }
    }
  }

  List<TripStop> get _currentDayStops =>
      _allStops.where((s) => s.dayNumber == _selectedDay).toList();

  // ── Statistics ──

  double get _totalDistanceKm {
    double total = 0;
    for (final stop in _allStops) {
      if (stop.distanceMeters != null) total += stop.distanceMeters!;
    }
    return total / 1000;
  }

  int get _totalStops => _allStops.length;

  int get _totalTravelMinutes {
    int total = 0;
    for (final stop in _allStops) {
      if (stop.travelMinutes != null) total += stop.travelMinutes!;
    }
    return total;
  }

  String get _effectiveTime {
    int totalMinutes = 0;
    
    final Map<int, List<TripStop>> dayMap = {};
    for (final stop in _allStops) {
      if (stop.visitTime?.isNotEmpty == true) {
        dayMap.putIfAbsent(stop.dayNumber, () => []).add(stop);
      }
    }
    
    for (final stops in dayMap.values) {
      if (stops.length < 2) continue;
      stops.sort((a, b) {
        if (a.isBasecamp && !b.isBasecamp) return -1;
        if (!a.isBasecamp && b.isBasecamp) return 1;
        return a.orderIndex.compareTo(b.orderIndex);
      });
      
      final firstStop = stops.first;
      final lastStop = stops.last;
      
      try {
        final firstParts = firstStop.visitTime!.split(':');
        final startMin = int.parse(firstParts[0]) * 60 + int.parse(firstParts[1]);
        
        int endMin = 0;
        if (lastStop.endTime != null && lastStop.endTime!.isNotEmpty) {
          final lastEndParts = lastStop.endTime!.split(':');
          endMin = int.parse(lastEndParts[0]) * 60 + int.parse(lastEndParts[1]);
        } else {
          final lastParts = lastStop.visitTime!.split(':');
          endMin = int.parse(lastParts[0]) * 60 + int.parse(lastParts[1]) + 60;
        }
        // Calculate daily travel minutes
        int dailyTravelMinutes = 0;
        for (final s in stops) {
          dailyTravelMinutes += (s.travelMinutes ?? 0);
        }

        if (endMin > startMin) {
          int dailySpan = endMin - startMin;
          // Subtract travel time to get pure effective time spent AT destinations
          int dailyStay = dailySpan - dailyTravelMinutes;
          if (dailyStay > 0) {
            totalMinutes += dailyStay;
          }
        }
      } catch (_) {}
    }
    
    if (totalMinutes == 0) return '-';
    
    return _formatMinutes(totalMinutes);
  }

  // ── Date helpers ──

  String _dayDate(int dayNumber) {
    if (_destination.startDate == null) return 'Day $dayNumber';
    try {
      final start = DateTime.parse(_destination.startDate!);
      final date = start.add(Duration(days: dayNumber - 1));
      return DateFormat('d MMM').format(date);
    } catch (_) {
      return 'Day $dayNumber';
    }
  }

  String _weatherText(int dayNumber) {
    final w = _weatherForecast[dayNumber];
    if (w == null) {
      return ''; // No longer showing fake mock weather
    }
    try {
      final condition = w['weather'][0]['main'] as String;
      final temp = (w['main']['temp'] as num).round();
      final icon = WeatherService.weatherIconPath(condition);
      return '$icon $temp°C';
    } catch (_) {
      return ''; 
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Radius bumi dalam meter
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  // ── CRUD Actions ──

  Future<void> _addStop({bool isBasecamp = false}) async {
    String? previousTime;
    if (_currentDayStops.isNotEmpty) {
      final lastStop = _currentDayStops.last;
      previousTime = (lastStop.endTime != null && lastStop.endTime!.isNotEmpty) 
          ? lastStop.endTime 
          : lastStop.visitTime;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddStopSheet(
        dayNumber: _selectedDay, 
        isBasecamp: isBasecamp,
        minStartTime: previousTime,
      ),
    );

    if (result != null && mounted) {
      double? distanceMeters;
      int? travelMinutes;
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      final transportMode = result['transport'] as String;

      // Distance and time will be calculated via API below
      distanceMeters = null;
      travelMinutes = null;

      final stop = TripStop(
        destinationId: _destination.id!,
        dayNumber: _selectedDay,
        orderIndex: isBasecamp ? -1 : _currentDayStops.where((s) => !s.isBasecamp).length,
        placeName: result['name'] as String,
        placeAddress: (result['address'] as String?)?.isEmpty ?? true ? null : result['address'],
        visitTime: result['time'] as String,
        endTime: result['endTime'] as String?,
        transportMode: transportMode,
        photoUrl: result['photoUrl'] as String?,
        latitude: lat,
        longitude: lng,
        distanceMeters: distanceMeters,
        travelMinutes: travelMinutes,
        isBasecamp: isBasecamp,
        otmXid: result['xid'] as String?,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _db.insertTripStop(stop);
      
      // Recalculate all distances for the day with the new stop using real routing API
      await _loadStops();
      final stopsToRecalculate = _currentDayStops; // capture once — getter returns a NEW list each call
      if (stopsToRecalculate.isNotEmpty) {
        await _recalculateDistancesAsync(stopsToRecalculate);
        await _db.updateTripStopOrder(stopsToRecalculate); // same list, now with distances filled in
        await _loadStops();
      }

      if (mounted) {
        showSuccessSnackbar(
          context,
          '${result['name']} ${tr('trip_added_success')}',
          icon: Icons.add_location_alt,
        );
      }
    }
  }

  Future<void> _recalculateDistancesAsync(List<TripStop> dayStops) async {
    // Sort dayStops explicitly: basecamp first, then by old orderIndex
    dayStops.sort((a, b) {
      if (a.isBasecamp && !b.isBasecamp) return -1;
      if (!a.isBasecamp && b.isBasecamp) return 1;
      return a.orderIndex.compareTo(b.orderIndex);
    });

    final ors = OpenRouteService();
    
    // Temukan basecamp dari hari sebelumnya jika hari ini tidak ada basecamp
    TripStop? effectiveBasecamp;
    if (dayStops.isNotEmpty && !dayStops.first.isBasecamp) {
      final allBasecamps = _allStops.where((s) => s.isBasecamp && s.dayNumber <= dayStops.first.dayNumber).toList();
      if (allBasecamps.isNotEmpty) {
        allBasecamps.sort((a, b) => b.dayNumber.compareTo(a.dayNumber));
        effectiveBasecamp = allBasecamps.first;
      }
    }

    for (int i = 0; i < dayStops.length; i++) {
      double? dist;
      int? mins;
      
      TripStop? prev;
      if (i > 0) {
        prev = dayStops[i - 1];
      } else if (i == 0 && effectiveBasecamp != null) {
        prev = effectiveBasecamp;
      }

      if (prev != null) {
        final curr = dayStops[i];
        if (prev.latitude != null && prev.longitude != null && curr.latitude != null && curr.longitude != null) {
          
          // Try fetching real-world data from ORS API
          try {
            final data = await ors.getDistanceAndDuration(
              LatLng(prev.latitude!, prev.longitude!),
              LatLng(curr.latitude!, curr.longitude!),
              curr.transportMode,
            );
            if (data != null) {
              dist = data['distance'];
              // ORS duration is in seconds, convert to minutes
              mins = ((data['duration'] as double) / 60.0).round();
            }
          } catch (_) {
            // Ignore API error and fallback to haversine below
          }

          // Fallback to Haversine if API failed
          if (dist == null || mins == null) {
            dist = _haversineDistance(prev.latitude!, prev.longitude!, curr.latitude!, curr.longitude!);
            double speedKmh = 5.0;
            if (curr.transportMode == 'car') speedKmh = 40.0;
            if (curr.transportMode == 'bike') speedKmh = 15.0;
            if (curr.transportMode == 'public') speedKmh = 30.0;
            mins = ((dist / 1000) / speedKmh * 60).round();
          }
        }
      }
      // explicit handling without relying on copyWith null coalescing to clear old distances
      double? finalDist;
      int? finalMins;
      
      // Basecamp hari tersebut tidak boleh memiliki jarak dari dirinya sendiri
      if (i == 0 && effectiveBasecamp == null) {
        finalDist = null;
        finalMins = null;
      } else {
        finalDist = dist;
        finalMins = mins;
      }

      dayStops[i] = TripStop(
        id: dayStops[i].id,
        destinationId: dayStops[i].destinationId,
        dayNumber: dayStops[i].dayNumber,
        orderIndex: dayStops[i].isBasecamp ? -1 : (dayStops.first.isBasecamp ? i - 1 : i),
        placeName: dayStops[i].placeName,
        placeAddress: dayStops[i].placeAddress,
        latitude: dayStops[i].latitude,
        longitude: dayStops[i].longitude,
        photoUrl: dayStops[i].photoUrl,
        openingHours: dayStops[i].openingHours,
        description: dayStops[i].description,
        otmXid: dayStops[i].otmXid,
        visitTime: dayStops[i].visitTime,
        endTime: dayStops[i].endTime,
        estimatedDurationMinutes: dayStops[i].estimatedDurationMinutes,
        transportMode: dayStops[i].transportMode,
        distanceMeters: finalDist,
        travelMinutes: finalMins,
        isBasecamp: dayStops[i].isBasecamp,
        createdAt: dayStops[i].createdAt,
      );
    }
  }

  Future<void> _deleteStop(TripStop stop) async {
    // Dialog konfirmasi sudah ditangani oleh Dismissible di TripTimelineItem
    // Jadi di sini langsung eksekusi penghapusan
    if (mounted) {
      await _db.deleteTripStop(stop.id!);
      final updatedStops = _currentDayStops.where((s) => s.id != stop.id).toList();
      await _recalculateDistancesAsync(updatedStops);
      await _db.updateTripStopOrder(updatedStops);
      await _loadStops();
      
      if (mounted) {
        showSuccessSnackbar(
          context,
          '"${stop.placeName}" ${tr('trip_deleted_success')}',
          icon: Icons.delete_outline,
        );
      }
    }
  }

  Future<void> _editStop(TripStop stop) async {
    String? previousTime;
    final index = _currentDayStops.indexWhere((s) => s.id == stop.id);
    if (index > 0) {
      final prevStop = _currentDayStops[index - 1];
      previousTime = (prevStop.endTime != null && prevStop.endTime!.isNotEmpty) 
          ? prevStop.endTime 
          : prevStop.visitTime;
    }

    String? nextTime;
    if (index != -1 && index < _currentDayStops.length - 1) {
      final nextStop = _currentDayStops[index + 1];
      nextTime = nextStop.visitTime;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddStopSheet(
        dayNumber: _selectedDay,
        isBasecamp: stop.isBasecamp,
        existingStop: stop,
        minStartTime: previousTime,
        maxEndTime: nextTime,
      ),
    );

    if (result != null && mounted) {
      final updatedStop = stop.copyWith(
        placeName: result['name'] as String,
        placeAddress: (result['address'] as String?)?.isEmpty ?? true ? null : result['address'],
        visitTime: result['time'] as String,
        endTime: result['endTime'] as String?,
        transportMode: result['transport'] as String,
        photoUrl: result['photoUrl'] as String?,
        latitude: result['lat'] as double?,
        longitude: result['lng'] as double?,
        otmXid: result['xid'] as String?,
      );

      await _db.updateTripStop(updatedStop);
      
      // Need to recalculate distances if location or transport mode changed
      final currentStops = List<TripStop>.from(_currentDayStops);
      final index = currentStops.indexWhere((s) => s.id == stop.id);
      if (index != -1) {
        currentStops[index] = updatedStop;
        await _recalculateDistancesAsync(currentStops);
        await _db.updateTripStopOrder(currentStops);
      }

      await _loadStops();
      if (mounted) {
        showSuccessSnackbar(
          context,
          '${result['name']} diperbarui',
          icon: Icons.edit_location_alt,
        );
      }
    }
  }

  Future<void> _addDay() async {
    if (_destination.tripDays > 0 && _maxDay >= _destination.tripDays) {
      if (mounted) {
        showErrorSnackbar(context, 'Maksimal durasi trip (${_destination.tripDays} hari) telah tercapai.');
      }
      return;
    }
    
    final newDay = _maxDay + 1;
    // Insert a placeholder stop to create the day
    final stop = TripStop(
      destinationId: _destination.id!,
      dayNumber: newDay,
      orderIndex: 0,
      placeName: tr('trip_new_place'),
      visitTime: '09:00',
      createdAt: DateTime.now().toIso8601String(),
    );
    await _db.insertTripStop(stop);
    await _loadStops();
    if (mounted) {
      setState(() => _selectedDay = newDay);
      _tabController.animateTo(newDay - 1);
    }
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final currentDayStops = _currentDayStops;
    final stop = currentDayStops.removeAt(oldIndex);
    currentDayStops.insert(newIndex, stop);
    
    // Update orderIndex and distances
    await _recalculateDistancesAsync(currentDayStops);

    if (mounted) {
      setState(() {
        // replace in all stops
        _allStops.removeWhere((s) => s.dayNumber == _selectedDay);
        _allStops.addAll(currentDayStops);
      });
    }

    await _db.updateTripStopOrder(currentDayStops);
  }

  Widget _transportChip(BuildContext ctx, String mode, IconData icon,
      String selected, ValueChanged<String> onSelected) {
    final isActive = mode == selected;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 18,
          color: isActive
              ? Theme.of(ctx).colorScheme.onPrimary
              : Theme.of(ctx).colorScheme.onSurface),
      label: Text(mode),
      selected: isActive,
      selectedColor: Theme.of(ctx).colorScheme.primary,
      labelStyle: TextStyle(
        color: isActive
            ? Theme.of(ctx).colorScheme.onPrimary
            : Theme.of(ctx).colorScheme.onSurface,
      ),
      onSelected: (_) => onSelected(mode),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final basecampStop = _currentDayStops.where((s) => s.isBasecamp).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _circleButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // ── Peta / Header (40% Layar) ──
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _headerBackground(),
                ),
              ],
            ),
          ),

          // ── Konten Bawah (60% Layar) ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // Judul Destinasi
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trName(_destination.name),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_destination.startDate != null && _destination.endDate != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.date_range, size: 16, color: colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_destination.startDate} → ${_destination.endDate} (${_destination.tripDays} hari)',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Statistics Strip ──
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _statItem(Icons.place, '$_totalStops', tr('trip_stat_places')),
                          const SizedBox(width: 12),
                          _statItem(Icons.swap_vert, '${_totalDistanceKm.toStringAsFixed(1)} km', tr('trip_stat_distance')),
                          const SizedBox(width: 12),
                          _statItem(Icons.schedule, _formatMinutes(_totalTravelMinutes), tr('trip_stat_travel_time')),
                          const SizedBox(width: 12),
                          _statItem(Icons.timer, _effectiveTime, tr('trip_stat_effective_time')),
                        ],
                      ),
                    ),
                  ),

                  // ── Day Tabs ──
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _DayTabDelegate(
                      tabBar: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TabBar(
                                      controller: _tabController,
                                      isScrollable: true,
                                      tabAlignment: TabAlignment.start,
                                      dividerColor: Colors.transparent,
                                      indicator: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      labelColor: colorScheme.onPrimary,
                                      unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
                                      indicatorPadding: EdgeInsets.zero,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                                      physics: const BouncingScrollPhysics(),
                                      tabs: List.generate(_maxDay, (i) {
                                        final dayNum = i + 1;
                                        final dateStr = _dayDate(dayNum);
                                        final weatherStr = _weatherText(dayNum);
                                        return Tab(
                                          height: 56,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  dateStr,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                if (weatherStr.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      weatherStr,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  if (_destination.tripDays == 0 || _maxDay < _destination.tripDays)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.add, color: colorScheme.onPrimaryContainer),
                                        tooltip: tr('trip_add_day'),
                                        onPressed: _addDay,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              height: 1,
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Basecamp UI ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildBasecampSection(basecampStop),
                    ),
                  ),

                  // ── Timeline Items ──
                  if (_currentDayStops.isEmpty)
                    SliverToBoxAdapter(
                      child: _emptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final stop = _currentDayStops[index];
                            final nextStop = index < _currentDayStops.length - 1 ? _currentDayStops[index + 1] : null;
                            final isLast = index == _currentDayStops.length - 1;
                            return TripTimelineItem(
                              key: ValueKey(stop.id ?? stop.createdAt),
                              stop: stop,
                              nextStop: nextStop,
                              isLast: isLast,
                              isFirst: index == 0,
                              index: index,
                              onEdit: () => _editStop(stop),
                              onDelete: () => _deleteStop(stop),
                            );
                          },
                          childCount: _currentDayStops.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: basecampStop == null 
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap set Titik Keberangkatan terlebih dahulu untuk hari ini')),
                );
              }
            : _addStop,
        backgroundColor: basecampStop == null ? colorScheme.surfaceContainerHighest : colorScheme.primary,
        foregroundColor: basecampStop == null ? colorScheme.onSurfaceVariant : colorScheme.onPrimary,
        elevation: basecampStop == null ? 0 : 4,
        icon: const Icon(Icons.add_location_alt),
        label: Text(tr('trip_add_stop')),
      ),
    );
  }

  // ── Widget Builders ──

  Widget _headerBackground() {
    final validStops = _currentDayStops.where((s) => s.latitude != null && s.longitude != null).toList();
    Widget background;
    
    if (validStops.isNotEmpty) {
      background = AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: TripMapWidget(
          key: ValueKey('map_day_$_selectedDay'),
          stops: _currentDayStops,
        ),
      );
    } else if (_destination.latitude != null && _destination.longitude != null) {
      background = FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(_destination.latitude!, _destination.longitude!),
          initialZoom: 12,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.example.wanderlist',
          ),
        ],
      );
    } else {
      final photoPath = _destination.photoPath;
      if (photoPath != null && photoPath.startsWith('http')) {
        background = Image.network(photoPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _headerPlaceholder());
      } else {
        background = _headerPlaceholder();
      }
    }

    return background;
  }

  Widget _headerPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      child: Center(
        child: Icon(Icons.map,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              tr('trip_empty'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('trip_empty_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasecampSection(TripStop? basecamp) {
    final colorScheme = Theme.of(context).colorScheme;
    if (basecamp != null) {
      // Basecamp is already rendered inside the SliverList for perfect alignment
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _addStop(isBasecamp: true),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, color: colorScheme.primary.withValues(alpha: 0.8)),
            const SizedBox(width: 12),
            Text(
              tr('trip_set_basecamp'),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon,
              color: Theme.of(context).colorScheme.onPrimary, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }

  // ── Formatting Helpers ──

  IconData _transportIcon(String mode) {
    switch (mode) {
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.directions_bike;
      case 'public':
        return Icons.directions_bus;
      case 'walk':
      default:
        return Icons.directions_walk;
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatMinutes(int minutes) {
    final hStr = tr('time_hour');
    final mStr = tr('time_minute');
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '$h$hStr $m$mStr' : '$h$hStr';
    }
    return '$minutes$mStr';
  }
}

// ── SliverPersistentHeader delegate for Day tabs ──

class _DayTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _DayTabDelegate({required this.tabBar});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _DayTabDelegate oldDelegate) => true;
}
