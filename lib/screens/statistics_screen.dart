import 'package:flutter/material.dart';

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getStatistics();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Perjalanan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ringkasan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    label: 'Total Destinasi',
                    count: _stats['total'] ?? 0,
                    icon: Icons.public,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 8),
                  StatCard(
                    label: 'Sudah Dikunjungi',
                    count: _stats['visited'] ?? 0,
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  StatCard(
                    label: 'Wishlist',
                    count: _stats['wishlist'] ?? 0,
                    icon: Icons.favorite,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Berdasarkan Kategori',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
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
            ),
    );
  }
}
