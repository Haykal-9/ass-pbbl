class ChecklistItem {
  final int? id;
  final int destinationId;
  final String label;
  final bool isDone;
  final int orderIndex;
  final String createdAt;

  const ChecklistItem({
    this.id,
    required this.destinationId,
    required this.label,
    required this.isDone,
    this.orderIndex = 0,
    required this.createdAt,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
        id: map['id'] as int?,
        destinationId: map['destination_id'] as int,
        label: map['label'] as String,
        isDone: (map['is_done'] as int) == 1,
        orderIndex: map['order_index'] as int? ?? 0,
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'destination_id': destinationId,
        'label': label,
        'is_done': isDone ? 1 : 0,
        'order_index': orderIndex,
        'created_at': createdAt,
      };

  ChecklistItem copyWith({bool? isDone, String? label, int? orderIndex}) => ChecklistItem(
        id: id,
        destinationId: destinationId,
        label: label ?? this.label,
        isDone: isDone ?? this.isDone,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt,
      );
}
