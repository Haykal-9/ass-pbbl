import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/destination.dart';
import '../services/app_locale.dart';
import '../widgets/category_chip.dart';
import '../widgets/destination_status_badge.dart';
import '../widgets/scratch_card.dart';
import 'detail_screen.dart';

class ScratchCardScreen extends StatefulWidget {
  final Destination destination;

  const ScratchCardScreen({super.key, required this.destination});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  final ScratchCardController _scratchController = ScratchCardController();
  bool _isRevealed = false;

  void _resetScratchCard() {
    _scratchController.reset();
    setState(() => _isRevealed = false);
  }

  Future<void> _openDetail() async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(destination: widget.destination),
      ),
    );
    if (deleted == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _destinationPhoto(BuildContext context) {
    final photoPath = widget.destination.photoPath;
    if (photoPath != null && photoPath.trim().isNotEmpty) {
      if (kIsWeb || photoPath.startsWith('http')) {
        return Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _photoPlaceholder(context),
        );
      }

      final photoFile = File(photoPath);
      if (photoFile.existsSync()) {
        return Image.file(
          photoFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _photoPlaceholder(context),
        );
      }
    }

    return _photoPlaceholder(context);
  }

  Widget _photoPlaceholder(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(_isRevealed ? 'scratch_title_revealed' : 'scratch_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ScratchCard(
                      controller: _scratchController,
                      overlayColor: colorScheme.primary,
                      hintText: tr('scratch_hint'),
                      progressLabel: tr('scratch_progress'),
                      onRevealed: () => setState(() => _isRevealed = true),
                      child: _destinationPhoto(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trName(widget.destination.name),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trCountry(widget.destination.country),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CategoryChip(widget.destination.category),
                              DestinationStatusBadge(
                                status: widget.destination.status,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      tr(_isRevealed ? 'scratch_revealed_msg' : 'scratch_hint'),
                      key: ValueKey(_isRevealed),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetScratchCard,
                          icon: const Icon(Icons.refresh),
                          label: Text(tr('scratch_reset')),
                        ),
                      ),
                      if (_isRevealed) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              FilledButton.icon(
                                    onPressed: _openDetail,
                                    icon: const Icon(Icons.open_in_new),
                                    label: Text(tr('scratch_view_detail')),
                                  )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    curve: Curves.easeOutBack,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
