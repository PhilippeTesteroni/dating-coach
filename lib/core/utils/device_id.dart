import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Утилита для работы с Device ID
/// 
/// Генерирует уникальный UUID при первом запуске
/// и сохраняет его в SharedPreferences
abstract class DeviceId {
  static const String _key = 'device_id';
  static String? _cachedDeviceId;

  /// Получить Device ID
  /// 
  /// Если ID уже существует — возвращает его
  /// Если нет — генерирует новый и сохраняет
  static Future<String> get() async {
    // Возвращаем кэш если есть
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Пробуем прочитать существующий
    String? deviceId = prefs.getString(_key);
    
    // Если нет — генерируем новый
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_key, deviceId);
    }
    
    // Кэшируем
    _cachedDeviceId = deviceId;
    
    return deviceId;
  }

  /// Проверить есть ли сохранённый Device ID
  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Очистить Device ID (для отладки/логаута)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _cachedDeviceId = null;
  }
}
