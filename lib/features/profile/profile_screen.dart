import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/api_client.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../services/characters_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_confirm_modal.dart';
import '../../shared/widgets/dc_header.dart';
import '../../app.dart';
import 'profile_edit_modal.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  late final ProfileRepository _profileRepository;

  @override
  void initState() {
    super.initState();
    ApiClient apiClient;
    try {
      apiClient = UserService().apiClient;
    } catch (_) {
      apiClient = ApiClient();
    }
    _profileRepository = ProfileRepository(apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Сначала пробуем взять из UserService (загружен на splash)
    final cachedProfile = UserService().profile;
    if (cachedProfile != null) {
      setState(() {
        _profile = cachedProfile;
        _isLoading = false;
      });
      return;
    }

    // Если нет - загружаем с сервера
    try {
      final profile = await _profileRepository.getProfile();
      UserService().updateProfile(profile); // Кэшируем
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      final userId = UserService().session?.userId ?? 'dev_user_123';
      setState(() {
        _profile = UserProfile(userId: userId);
        _isLoading = false;
      });
    }
  }

  void _copyUserId() {
    if (_profile == null) return;
    Clipboard.setData(ClipboardData(text: _profile!.userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User ID copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openEditScreen() async {
    if (_profile == null) return;
    
    final oldPreferredGender = _profile!.preferredGender;
    
    final result = await ProfileEditModal.show(
      context: context,
      profile: _profile!,
      onSave: (updated) async {
        try {
          await _profileRepository.updateProfile(
            name: updated.name,
            gender: updated.gender?.name,
            preferredGender: updated.preferredGender.name,
            ageRangeMin: updated.ageRangeMin,
            ageRangeMax: updated.ageRangeMax,
          );
        } catch (e) {
          // Dev mode fallback
        }
      },
    );
    
    if (result != null) {
      UserService().updateProfile(result); // Синхронизируем с кэшем
      
      // Инвалидируем кэш персонажей если изменился preferredGender
      if (result.preferredGender != oldPreferredGender) {
        CharactersService().invalidate();
        debugPrint('Characters cache invalidated: preferredGender changed');
      }
      
      setState(() => _profile = result);
    }
  }

  void _deleteChatsHistory() async {
    final confirmed = await DCConfirmModal.show(
      context: context,
      title: 'Clear chat history?',
      message: 'This will delete your chat history from this device.\nThis action can\'t be undone.',
      confirmText: 'Clear history',
      cancelText: 'Cancel',
    );

    if (confirmed == true && mounted) {
      // TODO: Actually delete chat history
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: AppTypography.bodyMedium))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                _buildEditButton(),
                const SizedBox(height: 24),
                _buildProfileFields(),
                const Spacer(),
                _buildDeleteButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return DCHeader(
      title: 'Profile',
      leading: const DCBackButton(),
    );
  }

  Widget _buildEditButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _openEditScreen,
        child: Text('Edit', style: AppTypography.buttonAccent),
      ),
    );
  }

  Widget _buildProfileFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField('Name', _profile?.name ?? '—'),
        const SizedBox(height: 20),
        _buildField('Age range for search', _profile?.ageRangeDisplay ?? '—'),
        const SizedBox(height: 20),
        _buildField('Preferred gender', _profile?.preferredGenderDisplay ?? '—'),
        const SizedBox(height: 20),
        _buildField('Your gender', _profile?.genderDisplay ?? '—'),
        const SizedBox(height: 20),
        _buildUserIdField(),
      ],
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.fieldLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.fieldValue),
      ],
    );
  }

  Widget _buildUserIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User ID', style: AppTypography.fieldLabel),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                _profile?.userId ?? '—',
                style: AppTypography.fieldValue,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _copyUserId,
              child: Icon(
                Icons.copy,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: GestureDetector(
        onTap: _deleteChatsHistory,
        child: Text('Delete chats history', style: AppTypography.linkText),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.privacy);
            },
            child: Text('Privacy Policy', style: AppTypography.linkText),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, Routes.terms);
            },
            child: Text('Terms & Conditions', style: AppTypography.linkText),
          ),
        ],
      ),
    );
  }
}
