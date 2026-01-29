import '../data/api/api_client.dart';
import '../data/models/user_balance.dart';
import '../data/models/user_session.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/profile_repository.dart';

/// Сервис пользователя
/// 
/// Singleton для хранения состояния пользователя:
/// - Сессия (userId, token)
/// - Баланс
/// - Профиль
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  UserSession? _session;
  UserBalance? _balance;
  UserProfile? _profile;
  UserRepository? _userRepository;
  ProfileRepository? _profileRepository;
  ApiClient? _apiClient;

  /// Текущая сессия
  UserSession? get session => _session;

  /// Текущий баланс
  int get balance => _balance?.balance ?? 0;

  /// Текущий профиль
  UserProfile? get profile => _profile;

  /// ApiClient для других репозиториев
  ApiClient get apiClient {
    if (_apiClient == null) {
      throw StateError('UserService not initialized. Call init() first.');
    }
    return _apiClient!;
  }

  /// Инициализация после авторизации
  void init({
    required UserSession session,
    required ApiClient apiClient,
  }) {
    _session = session;
    _apiClient = apiClient;
    _userRepository = UserRepository(apiClient);
    _profileRepository = ProfileRepository(apiClient);
  }

  /// Загрузить баланс с сервера
  Future<int> loadBalance() async {
    if (_userRepository == null) {
      throw StateError('UserService not initialized. Call init() first.');
    }
    
    try {
      _balance = await _userRepository!.getBalance();
      return _balance!.balance;
    } catch (e) {
      // При ошибке оставляем старый баланс или 0
      return _balance?.balance ?? 0;
    }
  }

  /// Загрузить профиль с сервера
  Future<UserProfile?> loadProfile() async {
    if (_profileRepository == null) {
      throw StateError('UserService not initialized. Call init() first.');
    }
    
    try {
      _profile = await _profileRepository!.getProfile();
      return _profile;
    } catch (e) {
      // При ошибке возвращаем null
      return null;
    }
  }

  /// Обновить баланс локально (после покупки/траты)
  void updateBalance(int newBalance) {
    _balance = UserBalance(balance: newBalance);
  }

  /// Обновить профиль локально
  void updateProfile(UserProfile profile) {
    _profile = profile;
  }

  /// Очистить данные (logout)
  void clear() {
    _session = null;
    _balance = null;
    _profile = null;
    _userRepository = null;
    _profileRepository = null;
  }
}
