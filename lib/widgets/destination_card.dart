import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/app_locale.dart';
import 'category_chip.dart';
import 'destination_status_badge.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final bool isGrid;
  final bool showChecklistProgress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.isGrid,
    this.showChecklistProgress = false,
    required this.onTap,
    required this.onDelete,
  });

  Widget _photo({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (destination.photoPath != null) {
      if (kIsWeb || destination.photoPath!.startsWith('http')) {
        return Image.network(
          destination.photoPath!,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(height, width),
        );
      } else {
        final f = File(destination.photoPath!);
        if (f.existsSync()) {
          return Image.file(
            f,
            height: height,
            width: width,
            fit: fit,
            errorBuilder: (_, __, ___) => _placeholder(height, width),
          );
        }
      }
    }
    return _placeholder(height, width);
  }

  Widget _placeholder(double? height, double? width) {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: Icon(Icons.landscape, size: 40, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _photo(width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trName(destination.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      trCountry(destination.country),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CategoryChip(destination.category),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        DestinationStatusBadge(
                          status: destination.status,
                        ),
                      ],
                    ),
                    _buildChecklistProgress(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // List mode
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: _photo(width: 90, height: 90),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trName(destination.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      trCountry(destination.country),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CategoryChip(destination.category),
                        DestinationStatusBadge(
                          status: destination.status,
                        ),
                      ],
                    ),
                    _buildChecklistProgress(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildChecklistProgress(BuildContext context) {
    if (!showChecklistProgress || destination.checklistTotal == 0) {
      return const SizedBox.shrink();
    }
    
    final total = destination.checklistTotal;
    final done = destination.checklistDone;
    final progress = total > 0 ? done / total : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.green, width: 1.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: progress == 1.0 ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
