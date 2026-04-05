class MemoView {
  final int id;
  final String name;
  final int displayOrder;

  const MemoView({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'display_order': displayOrder,
      };

  factory MemoView.fromMap(Map<String, dynamic> map) => MemoView(
        id: map['id'] as int,
        name: map['name'] as String,
        displayOrder: map['display_order'] as int,
      );
}
