class LessonModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final int orderIndex;

  const LessonModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.orderIndex,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        category: json['category'] as String,
        orderIndex: json['order_index'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'order_index': orderIndex,
      };
}

