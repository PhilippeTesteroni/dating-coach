import 'package:flutter/material.dart';
import '../../app.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../services/app_settings_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/characters_service.dart';
import '../../shared/widgets/dc_scaffold.dart';
import '../../shared/widgets/dc_loader.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Splash Screen для Dating Coach
/// 
/// Показывает loader пока идёт:
/// - Инициализация Firebase
/// - Авторизация пользователя (register/login)
/// - Загрузка баланса
/// - Загрузка профиля
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // TODO: Вынести в конфиг/env
  static const bool _skipAuth = false; // Для тестирования без бэкенда
  
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Dev-режим: пропускаем авторизацию, ставим фейковый баланс
    if (_skipAuth) {
      // Фейковый баланс для тестирования UI
      UserService().updateBalance(12);
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.modeSelection);
      }
      return;
    }

    try {
      // Создаём зависимости
      // TODO: Вынести в DI/Provider
      final apiClient = ApiClient();
      final authRepository = AuthRepository(apiClient);
      final authService = AuthService(
        authRepository: authRepository,
        apiClient: apiClient,
      );

      // 1. Инициализируем сессию (register/login)
      final session = await authService.initSession();

      // 2. Инициализируем UserService
      UserService().init(
        session: session,
        apiClient: apiClient,
      );

      // 3. Инициализируем CharactersService
      CharactersService().init(apiClient);

      // 4. Инициализируем AppSettingsService
      AppSettingsService().init(apiClient);

      // 5. Загружаем данные параллельно
      await Future.wait([
        UserService().loadSubscriptionStatus(),
        UserService().loadProfile(),
        AppSettingsService().loadSettings(),
      ]);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.modeSelection);
      }
    } catch (e) {
      // При ошибке показываем сообщение
      debugPrint('🔴 Splash init error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to connect. Please try again.\n\nError: $e';
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return DCScaffold(
      showMenu: false,
      child: Center(
        child: _isLoading 
            ? const DCLoader(size: 32, strokeWidth: 1.0)
            : _buildError(),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _errorMessage ?? 'Unknown error',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _retry,
          child: Text(
            'Tap to retry',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
