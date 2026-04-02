class ViewItem {
  final int? id;
  final int viewId;
  final int memoId;
  final int posIndex;

  const ViewItem({
    this.id,
    required this.viewId,
    required this.memoId,
    required this.posIndex,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'view_id': viewId,
        'memo_id': memoId,
        'pos_index': posIndex,
      };

  factory ViewItem.fromMap(Map<String, dynamic> map) => ViewItem(
        id: map['id'] as int?,
        viewId: map['view_id'] as int,
        memoId: map['memo_id'] as int,
        posIndex: map['pos_index'] as int,
      );
}
