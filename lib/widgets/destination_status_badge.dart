import 'package:flutter/material.dart';

import '../services/app_locale.dart';

class DestinationStatusBadge extends StatelessWidget {
  final String status;

  const DestinationStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isVisited = status == 'visited';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVisited ? Icons.check_circle : Icons.favorite,
            size: 14,
            color: isVisited ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 5),
          Text(
            isVisited ? tr('status_visited') : tr('status_wishlist'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isVisited ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }
}
