/// Модель сессии пользователя
/// 
/// Хранит данные авторизации
class UserSession {
  final String userId;
  final String token;
  final String deviceId;
  final DateTime? expiresAt;

  const UserSession({
    required this.userId,
    required this.token,
    required this.deviceId,
    this.expiresAt,
  });

  /// Создать из JSON (ответ API)
  factory UserSession.fromJson(Map<String, dynamic> json, String deviceId) {
    return UserSession(
      userId: json['user_id'] as String,
      token: json['token'] as String,
      deviceId: deviceId,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// Преобразовать в JSON (для локального хранения)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'token': token,
      'device_id': deviceId,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Проверить истёк ли токен
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  String toString() {
    return 'UserSession(userId: $userId, deviceId: $deviceId, isExpired: $isExpired)';
  }
}
