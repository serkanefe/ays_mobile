class Announcement {
  final int? id;
  final String title;
  final String content;
  final int createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final bool isPinned;
  final bool isActive;

  Announcement({
    this.id,
    required this.title,
    required this.content,
    required this.createdBy,
    this.createdByName,
    this.createdAt,
    this.isPinned = false,
    this.isActive = true,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdBy: json['created_by'] ?? 0,
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isPinned: json['is_pinned'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_by': createdBy,
      'is_pinned': isPinned,
      'is_active': isActive,
    };
  }
}
