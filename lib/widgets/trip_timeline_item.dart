import 'dart:io';
import 'package:flutter/material.dart';

import '../models/trip_stop.dart';
import '../services/app_locale.dart';

class TripTimelineItem extends StatefulWidget {
  final TripStop stop;
  final TripStop? nextStop; // kept for API compat
  final bool isLast;
  final bool isFirst;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TripTimelineItem({
    super.key,
    required this.stop,
    this.nextStop,
    required this.isLast,
    this.isFirst = false,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<TripTimelineItem> createState() => _TripTimelineItemState();
}

class _TripTimelineItemState extends State<TripTimelineItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTransitInfo = widget.stop.distanceMeters != null || widget.stop.travelMinutes != null;
    final showTransit = hasTransitInfo || widget.stop.isBasecamp;

    return Dismissible(
      key: ValueKey('trip_stop_${widget.stop.id}'),
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
            content: Text('${tr('trip_delete_confirm')} "${widget.stop.placeName}"?'),
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
      onDismissed: (_) => widget.onDelete(),
      child: Stack(
        children: [
          // ── Timeline line ──
          if (!widget.isLast)
            Positioned(
              top: 44,
              bottom: 0,
              left: 27,
              width: 1,
              child: Container(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
              ),
            ),
          // ── Main Content ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Time ──
              SizedBox(
                width: 55,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    widget.stop.visitTime ?? '--:--',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
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
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Top row: Photo + Title ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              bottomLeft: Radius.circular(showTransit && !_isExpanded ? 0 : 12),
                            ),
                            child: widget.stop.photoUrl != null && widget.stop.photoUrl!.isNotEmpty
                                ? (widget.stop.photoUrl!.startsWith('http')
                                    ? Image.network(
                                        widget.stop.photoUrl!,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholderImg(colorScheme),
                                      )
                                    : Image.file(
                                        File(widget.stop.photoUrl!),
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholderImg(colorScheme),
                                      ))
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
                                    widget.stop.placeName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.stop.placeAddress != null && widget.stop.placeAddress!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        widget.stop.placeAddress!,
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
                            padding: EdgeInsets.only(right: widget.stop.isBasecamp ? 12 : 0),
                            child: AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(Icons.expand_more,
                                  color: colorScheme.onSurface.withValues(alpha: 0.3), size: 20),
                            ),
                          ),
                        ],
                      ),
                      
                      // ── Expanded Content ──
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isExpanded
                            ? Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.stop.description != null && widget.stop.description!.isNotEmpty) ...[
                                      Text(
                                        widget.stop.description!,
                                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.8)),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (widget.stop.latitude != null && widget.stop.longitude != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 14, color: colorScheme.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.stop.latitude!.toStringAsFixed(4)}, ${widget.stop.longitude!.toStringAsFixed(4)}',
                                            style: TextStyle(fontSize: 12, color: colorScheme.primary),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: widget.onEdit,
                                          icon: Icon(Icons.edit, size: 14, color: colorScheme.primary),
                                          label: Text('Edit', style: TextStyle(color: colorScheme.primary, fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        OutlinedButton.icon(
                                          onPressed: widget.onDelete,
                                          icon: Icon(Icons.delete_outline, size: 14, color: colorScheme.error),
                                          label: Text('Hapus', style: TextStyle(color: colorScheme.error, fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    // ── Transit info strip (inside the card) ──
                    if (showTransit)
                      Container(
                        width: double.infinity,
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
                              _transportIcon(widget.stop.transportMode),
                              widget.stop.isBasecamp ? '-' : widget.stop.transportMode,
                            ),
                            _transitChip(
                              context,
                              Icons.straighten,
                              widget.stop.distanceMeters != null ? _formatDistance(widget.stop.distanceMeters!) : '-',
                            ),
                            _transitChip(
                              context,
                              Icons.schedule,
                              widget.stop.travelMinutes != null ? _formatMinutes(widget.stop.travelMinutes!) : '-',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        ],
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
      width: 76,
      height: 76,
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
