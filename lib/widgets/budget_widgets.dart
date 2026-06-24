import 'package:flutter/material.dart';

import '../models/budget_item.dart';
import '../services/app_locale.dart';
import '../services/currency_service.dart';

class BudgetSummaryCard extends StatelessWidget {
  final double totalAmount;
  final int itemCount;

  const BudgetSummaryCard({
    super.key,
    required this.totalAmount,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
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
                  tr('budget_total'),
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyService.format(totalAmount),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount ${tr('budget_items_count')}',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.savings_outlined,
            color: colorScheme.onPrimary,
            size: 44,
          ),
        ],
      ),
    );
  }
}

class BudgetItemCard extends StatelessWidget {
  final BudgetItem item;
  final IconData icon;
  final String categoryLabel;
  final VoidCallback onTap;
  final Future<bool?> Function()? confirmDismiss;
  final VoidCallback onDelete;

  const BudgetItemCard({
    super.key,
    required this.item,
    required this.icon,
    required this.categoryLabel,
    required this.onTap,
    this.confirmDismiss,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      color: Theme.of(context).cardColor,
      child: Dismissible(
        key: Key('budget_${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_sweep, color: Colors.white),
        ),
        confirmDismiss: confirmDismiss,
        onDismissed: (_) => onDelete(),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            item.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(categoryLabel),
          trailing: Text(
            CurrencyService.format(item.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}