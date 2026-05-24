import 'dart:io';

import 'package:flutter/material.dart';

import '../models/destination.dart';
import 'category_chip.dart';

class DestinationCard extends StatelessWidget {
  final Destination destination;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.isGrid,
    required this.onTap,
    required this.onDelete,
  });

  Widget _photo({double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (destination.photoPath != null) {
      final f = File(destination.photoPath!);
      return Image.file(f, height: height, width: width, fit: fit);
    }
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: Icon(Icons.landscape, size: 40, color: Colors.grey[400]),
    );
  }

  Widget _statusBadge() {
    final isVisited = destination.status == 'visited';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVisited
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVisited
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        isVisited ? 'Visited' : 'Wishlist',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isVisited ? Colors.green[700] : Colors.orange[700],
        ),
      ),
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
                      destination.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      destination.country,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CategoryChip(destination.category),
                        const Spacer(),
                        _statusBadge(),
                      ],
                    ),
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
                      destination.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      destination.country,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CategoryChip(destination.category),
                        const SizedBox(width: 8),
                        _statusBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
