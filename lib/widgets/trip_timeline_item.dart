import 'package:flutter/material.dart';

import '../models/trip_stop.dart';
import '../services/app_locale.dart';

class TripTimelineItem extends StatelessWidget {
  final TripStop stop;
  final TripStop? nextStop; // kept for API compat
  final bool isLast;
  final bool isFirst;
  final VoidCallback onDelete;

  const TripTimelineItem({
    super.key,
    required this.stop,
    this.nextStop,
    required this.isLast,
    this.isFirst = false,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTransitInfo = stop.distanceMeters != null || stop.travelMinutes != null;
    final showTransit = !isFirst && hasTransitInfo;

    return Dismissible(
      key: ValueKey('trip_stop_${stop.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(tr('confirm_delete')),
            content: Text('${tr('trip_delete_confirm')} "${stop.placeName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('delete')),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Time + Timeline line ──
            SizedBox(
              width: 55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      stop.visitTime ?? '--:--',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        color: colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Right Content ──
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Top row: Photo + Title ──
                    Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            bottomLeft: Radius.circular(showTransit ? 0 : 12),
                          ),
                          child: stop.photoUrl != null && stop.photoUrl!.isNotEmpty
                              ? Image.network(
                                  stop.photoUrl!,
                                  width: 110,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholderImg(colorScheme),
                                )
                              : _placeholderImg(colorScheme),
                        ),
                        // Title + address
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  stop.placeName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (stop.placeAddress != null && stop.placeAddress!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      stop.placeAddress!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Chevron
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.expand_more,
                              color: colorScheme.onSurface.withValues(alpha: 0.3), size: 20),
                        ),
                      ],
                    ),
                    // ── Transit info strip (inside the card) ──
                    if (showTransit)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.06),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _transitChip(
                              context,
                              _transportIcon(stop.transportMode),
                              stop.transportMode,
                            ),
                            if (stop.distanceMeters != null)
                              _transitChip(
                                context,
                                Icons.straighten,
                                _formatDistance(stop.distanceMeters!),
                              ),
                            if (stop.travelMinutes != null)
                              _transitChip(
                                context,
                                Icons.schedule,
                                _formatMinutes(stop.travelMinutes!),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _transitChip(BuildContext context, IconData icon, String label) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }

  Widget _placeholderImg(ColorScheme colorScheme) {
    return Container(
      width: 110,
      height: 90,
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Icon(Icons.image, color: colorScheme.onSurface.withValues(alpha: 0.25)),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toInt()} m';
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (m == 0) return '$h hr';
      return '$h hr $m min';
    }
    return '$minutes min';
  }

  IconData _transportIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'walk':
        return Icons.directions_walk;
      case 'drive':
      case 'car':
        return Icons.directions_car;
      case 'transit':
      case 'bus':
      case 'public':
        return Icons.directions_bus;
      case 'bike':
        return Icons.directions_bike;
      case 'train':
        return Icons.directions_transit;
      case 'flight':
        return Icons.flight;
      default:
        return Icons.directions_walk;
    }
  }
}
