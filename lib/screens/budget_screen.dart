// Estimasi Budget Wisata — CRUD budget items per destinasi.

import 'package:flutter/material.dart';

import '../models/budget_item.dart';
import '../models/destination.dart';
import '../services/app_locale.dart';
import '../services/currency_service.dart';
import '../services/database_helper.dart';

/// Budget categories with their display icons.
const Map<String, IconData> kBudgetCategories = {
  'transport': Icons.flight_takeoff,
  'akomodasi': Icons.hotel,
  'makanan': Icons.restaurant,
  'aktivitas': Icons.local_activity,
  'lainnya': Icons.category,
};

String budgetCategoryLabel(String key) {
  switch (key) {
    case 'transport':
      return tr('budget_cat_transport');
    case 'akomodasi':
      return tr('budget_cat_akomodasi');
    case 'makanan':
      return tr('budget_cat_makanan');
    case 'aktivitas':
      return tr('budget_cat_aktivitas');
    default:
      return tr('budget_cat_lainnya');
  }
}

class BudgetScreen extends StatefulWidget {
  final Destination destination;

  const BudgetScreen({super.key, required this.destination});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<BudgetItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _db.getBudgetItems(widget.destination.id!);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  double get _total => _items.fold(0.0, (sum, i) => sum + i.amount);

  Future<void> _deleteItem(int id) async {
    await _db.deleteBudgetItem(id);
    await _loadItems();
  }

  Future<void> _openEditor({BudgetItem? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetEditorSheet(
        destinationId: widget.destination.id!,
        existing: existing,
      ),
    );
    if (saved == true) await _loadItems();
  }

  Future<bool?> _confirmDeleteItem(BudgetItem item) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('confirm_delete')),
        content: Text('${tr('delete')} "${item.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${tr('budget_title')} · ${trName(widget.destination.name)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        foregroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _totalHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) =>
                            _budgetTile(_items[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(tr('budget_add')),
      ),
    );
  }

  Widget _totalHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyService.format(_total),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_items.length} ${tr('budget_items_count')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 12,
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

  Widget _budgetTile(BudgetItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
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
        confirmDismiss: (_) => _confirmDeleteItem(item),
        onDismissed: (_) => _deleteItem(item.id!),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              kBudgetCategories[item.category] ?? Icons.category,
              color: Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            item.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(budgetCategoryLabel(item.category)),
          trailing: Text(
            CurrencyService.format(item.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          onTap: () => _openEditor(existing: item),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('budget_empty'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('budget_empty_hint'),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet form for creating / editing a single budget item.
class _BudgetEditorSheet extends StatefulWidget {
  final int destinationId;
  final BudgetItem? existing;

  const _BudgetEditorSheet({
    required this.destinationId,
    this.existing,
  });

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _amountCtrl;
  late String _category;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _category = e?.category ?? 'transport';
    // Show the stored base amount converted into the active currency.
    _amountCtrl = TextEditingController(
      text: e == null
          ? ''
          : _trimZeros(CurrencyService.fromBase(e.amount)),
    );
  }

  String _trimZeros(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final entered = CurrencyService.parseInput(_amountCtrl.text) ?? 0;
    final amountInBase = CurrencyService.toBase(entered);

    if (_isEdit) {
      await _db.updateBudgetItem(
        widget.existing!.copyWith(
          label: _labelCtrl.text.trim(),
          category: _category,
          amount: amountInBase,
        ),
      );
    } else {
      await _db.insertBudgetItem(
        BudgetItem(
          destinationId: widget.destinationId,
          label: _labelCtrl.text.trim(),
          category: _category,
          amount: amountInBase,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEdit ? tr('budget_edit') : tr('budget_add'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: tr('budget_label'),
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? tr('required_field')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('budget_amount'),
                  prefixText: '${CurrencyService.symbol()} ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  final parsed = CurrencyService.parseInput(v ?? '');
                  if (parsed == null || parsed <= 0) {
                    return tr('budget_amount_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: tr('budget_category'),
                  prefixIcon: Icon(kBudgetCategories[_category]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: kBudgetCategories.keys
                    .map((k) => DropdownMenuItem(
                          value: k,
                          child: Text(budgetCategoryLabel(k)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? tr('saving') : tr('save')),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
