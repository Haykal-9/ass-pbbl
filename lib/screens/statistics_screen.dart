import 'package:flutter/material.dart';

import '../services/app_locale.dart';
import '../services/currency_service.dart';
import '../services/database_helper.dart';
import '../widgets/stat_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, int> _stats = {};
  double _totalBudget = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getStatistics();
    final totalBudget = await _db.getTotalBudget();
    if (mounted) {
      setState(() {
        _stats = stats;
        _totalBudget = totalBudget;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(tr('stats_summary')),
          const SizedBox(height: 8),
          StatCard(
            label: tr('stats_total'),
            count: _stats['total'] ?? 0,
            icon: Icons.public,
            color: Colors.teal,
          ),
          const SizedBox(height: 8),
          StatCard(
            label: tr('stats_visited'),
            count: _stats['visited'] ?? 0,
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          StatCard(
            label: tr('stats_in_trip'),
            count: _stats['in_trip'] ?? 0,
            icon: Icons.flight_takeoff,
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          StatCard(
            label: 'Wishlist',
            count: _stats['wishlist'] ?? 0,
            icon: Icons.favorite,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          _sectionHeader(tr('stats_budget')),
          const SizedBox(height: 8),
          _budgetCard(),
          const SizedBox(height: 24),
          _sectionHeader(tr('stats_by_category')),
          const SizedBox(height: 8),
          StatCard(
            label: 'Wisata Alam',
            count: _stats['wisata_alam'] ?? 0,
            icon: Icons.park,
            color: Colors.green,
          ),
          const SizedBox(height: 8),
          StatCard(
            label: 'Budaya & Sejarah',
            count: _stats['budaya_sejarah'] ?? 0,
            icon: Icons.account_balance,
            color: Colors.brown,
          ),
          const SizedBox(height: 8),
          StatCard(
            label: 'Kota & Urban',
            count: _stats['kota_urban'] ?? 0,
            icon: Icons.location_city,
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  Widget _budgetCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('stats_total_budget'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyService.format(_totalBudget),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.savings_outlined, color: Theme.of(context).colorScheme.onPrimary, size: 44),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
