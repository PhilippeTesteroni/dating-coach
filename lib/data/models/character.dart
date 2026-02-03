/// Модель персонажа для Dating Coach
class Character {
  final String id;
  final String type; // 'coach' или 'character'
  final String name;
  final String description;
  final String gender;
  final String avatarUrl;
  final String thumbUrl;

  const Character({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.gender,
    required this.avatarUrl,
    required this.thumbUrl,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      gender: json['gender'] as String,
      avatarUrl: json['avatar_url'] as String,
      thumbUrl: json['thumb_url'] as String,
    );
  }

  /// Это коуч (Hitch)?
  bool get isCoach => type == 'coach';
  
  /// Это персонаж для практики?
  bool get isCharacter => type == 'character';
}
