class Memo {
  final int? id;
  final String title;
  final String content;
  final String emoji;
  final DateTime createdAt;

  Memo({
    this.id,
    required this.title,
    required this.content,
    required this.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      emoji: map['emoji'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
