class BudgetItem {
  final int? id;
  final int destinationId;
  final String label;

  /// Budget category: transport | akomodasi | makanan | aktivitas | lainnya
  final String category;

  /// Estimated cost, always stored in the base currency (IDR).
  final double amount;

  final String createdAt;

  const BudgetItem({
    this.id,
    required this.destinationId,
    required this.label,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  factory BudgetItem.fromMap(Map<String, dynamic> map) => BudgetItem(
        id: map['id'] as int?,
        destinationId: map['destination_id'] as int,
        label: map['label'] as String,
        category: map['category'] as String? ?? 'lainnya',
        amount: (map['amount'] as num).toDouble(),
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'destination_id': destinationId,
        'label': label,
        'category': category,
        'amount': amount,
        'created_at': createdAt,
      };

  BudgetItem copyWith({
    String? label,
    String? category,
    double? amount,
  }) =>
      BudgetItem(
        id: id,
        destinationId: destinationId,
        label: label ?? this.label,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        createdAt: createdAt,
      );
}
