import 'package:flutter/material.dart';

import '../services/app_locale.dart';

class DestinationStatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;

  const DestinationStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final isVisited = status == 'visited';
    final isInTrip = status == 'in_trip';
    
    Color color;
    if (isVisited) {
      color = Colors.green;
    } else if (isInTrip) {
      color = Colors.blue;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              isVisited
                  ? Icons.check_circle
                  : (isInTrip ? Icons.flight_takeoff : Icons.favorite),
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isVisited
                ? tr('status_visited')
                : (isInTrip ? tr('status_in_trip') : tr('status_wishlist')),
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
