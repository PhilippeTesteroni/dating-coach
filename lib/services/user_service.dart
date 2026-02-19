import '../data/api/api_client.dart';
import '../data/models/subscription_status.dart';
import '../data/models/user_balance.dart';
import '../data/models/user_session.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/profile_repository.dart';

/// Сервис пользователя
/// 
/// Singleton для хранения состояния пользователя:
/// - Сессия (userId, token)
/// - Подписка / free-tier статус
/// - Профиль
/// - Баланс (legacy, для backward compatibility)
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  UserSession? _session;
  SubscriptionStatus? _subscriptionStatus;
  UserBalance? _balance;
  UserProfile? _profile;
  UserRepository? _userRepository;
  ProfileRepository? _profileRepository;
  SubscriptionRepository? _subscriptionRepository;
  ApiClient? _apiClient;

  /// Текущая сессия
  UserSession? get session => _session;

  /// Подписка активна?
  bool get isSubscribed => _subscriptionStatus?.isSubscribed ?? false;

  /// Можно ли отправить сообщение (подписка или free-tier не исчерпан)
  bool get canSendMessage => _subscriptionStatus?.canSendMessage ?? true;

  /// Сколько сообщений осталось (null = безлимит)
  int? get messagesRemaining => _subscriptionStatus?.messagesRemaining;

  /// Сколько сообщений использовано
  int get messagesUsed => _subscriptionStatus?.messagesUsed ?? 0;

  /// Лимит бесплатных сообщений
  int get freeMessageLimit => _subscriptionStatus?.freeMessageLimit ?? 10;

  /// Полный объект статуса подписки
  SubscriptionStatus? get subscriptionStatus => _subscriptionStatus;

  /// Текущий баланс (legacy)
  int get balance => _balance?.balance ?? 0;

  /// Текущий профиль
  UserProfile? get profile => _profile;

  /// Профиль заполнен (имя + пол указаны)
  bool get isProfileComplete {
    final p = _profile;
    if (p == null) return false;
    return (p.name != null && p.name!.trim().length >= 2) && p.gender != null;
  }

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
    _subscriptionRepository = SubscriptionRepository(apiClient);
  }

  /// Загрузить статус подписки с сервера
  Future<SubscriptionStatus?> loadSubscriptionStatus() async {
    if (_subscriptionRepository == null) {
      throw StateError('UserService not initialized. Call init() first.');
    }

    try {
      _subscriptionStatus = await _subscriptionRepository!.getSubscriptionStatus();
      return _subscriptionStatus;
    } catch (e) {
      return _subscriptionStatus;
    }
  }

  /// Загрузить баланс с сервера (legacy)
  Future<int> loadBalance() async {
    if (_userRepository == null) {
      throw StateError('UserService not initialized. Call init() first.');
    }
    
    try {
      _balance = await _userRepository!.getBalance();
      return _balance!.balance;
    } catch (e) {
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
      return null;
    }
  }

  /// Обновить статус подписки локально (после покупки)
  void updateSubscriptionStatus(SubscriptionStatus status) {
    _subscriptionStatus = status;
  }

  /// Обновить баланс локально (legacy)
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
    _subscriptionStatus = null;
    _balance = null;
    _profile = null;
    _userRepository = null;
    _profileRepository = null;
    _subscriptionRepository = null;
  }
}
