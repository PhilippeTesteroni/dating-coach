enum Gender { male, female, other }

enum PreferredGender { all, male, female }

class UserProfile {
  final String userId;
  final String? name;
  final Gender? gender;
  final PreferredGender preferredGender;
  final int ageRangeMin;
  final int ageRangeMax;
  final String? avatarUrl;

  UserProfile({
    required this.userId,
    this.name,
    this.gender,
    this.preferredGender = PreferredGender.all,
    this.ageRangeMin = 18,
    this.ageRangeMax = 99,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? '',
      name: json['name'],
      gender: _parseGender(json['gender']),
      preferredGender: _parsePreferredGender(json['preferred_gender']),
      ageRangeMin: json['age_range_min'] ?? 18,
      ageRangeMax: json['age_range_max'] ?? 99,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender?.name,
      'preferred_gender': preferredGender.name,
      'age_range_min': ageRangeMin,
      'age_range_max': ageRangeMax,
      'avatar_url': avatarUrl,
    };
  }

  static Gender? _parseGender(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Gender.other,
    );
  }

  static PreferredGender _parsePreferredGender(String? value) {
    if (value == null) return PreferredGender.all;
    return PreferredGender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PreferredGender.all,
    );
  }

  String get genderDisplay {
    if (gender == null) return '—';
    switch (gender!) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  String get preferredGenderDisplay {
    switch (preferredGender) {
      case PreferredGender.all:
        return 'All';
      case PreferredGender.male:
        return 'Male';
      case PreferredGender.female:
        return 'Female';
    }
  }

  String get ageRangeDisplay => '$ageRangeMin - $ageRangeMax';

  String get shortUserId {
    if (userId.length > 10) {
      return 'user_${userId.substring(userId.length - 6)}';
    }
    return 'user_$userId';
  }

  UserProfile copyWith({
    String? userId,
    Object? name = const _Undefined(),
    Object? gender = const _Undefined(),
    PreferredGender? preferredGender,
    int? ageRangeMin,
    int? ageRangeMax,
    Object? avatarUrl = const _Undefined(),
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name is _Undefined ? this.name : name as String?,
      gender: gender is _Undefined ? this.gender : gender as Gender?,
      preferredGender: preferredGender ?? this.preferredGender,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
      avatarUrl: avatarUrl is _Undefined ? this.avatarUrl : avatarUrl as String?,
    );
  }
}

class _Undefined {
  const _Undefined();
}
