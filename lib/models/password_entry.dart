class PasswordEntry {
  const PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.category,
    required this.tags,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String username;
  final String password;
  final String url;
  final String category;
  final List<String> tags;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? url,
    String? category,
    List<String>? tags,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> get allTags {
    final values = <String>[
      category,
      ...tags,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    return values;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'url': url,
      'category': category,
      'tags': tags,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    final legacyCategory = (json['category'] as String? ?? '').trim();

    final rawTags = (json['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => (e as String).trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final merged = <String>{
      if (legacyCategory.isNotEmpty) legacyCategory,
      ...rawTags,
    }.toList();

    return PasswordEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      url: json['url'] as String? ?? '',
      category: merged.isEmpty ? '' : merged.first,
      tags: merged.length <= 1 ? <String>[] : merged.sublist(1),
      note: json['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
