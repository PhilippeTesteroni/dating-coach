import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../services/characters_service.dart';
import '../../services/user_service.dart';
import '../../shared/navigation/dc_page_route.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_buttons.dart';
import '../../shared/widgets/dc_help_button.dart';
import '../../shared/widgets/dc_modal.dart';
import '../../shared/widgets/dc_option_card.dart';
import '../../shared/widgets/dc_progress_dots.dart';
import '../../shared/widgets/dc_range_selector.dart';
import '../../shared/widgets/dc_text_field.dart';

/// Онбординг — сбор профиля перед первым чатом
///
/// 4 шага: имя → пол → кого ищешь → возрастной диапазон.
/// После завершения — навигация к [destination].
class OnboardingScreen extends StatefulWidget {
  final Widget destination;

  const OnboardingScreen({super.key, required this.destination});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _totalSteps = 4;

  int _currentStep = 0;
  bool _isSaving = false;

  // Step data
  final _nameController = TextEditingController();
  Gender? _gender;
  PreferredGender? _preferredGender;
  double _ageRangeMin = 22;
  double _ageRangeMax = 35;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().length >= 2;
      case 1:
        return _gender != null;
      case 2:
        return _preferredGender != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    final needsKeyboardDismiss = FocusScope.of(context).hasFocus;
    FocusScope.of(context).unfocus();

    if (needsKeyboardDismiss) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _complete();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);

    try {
      final repo = ProfileRepository(UserService().apiClient);
      await repo.updateProfile(
        name: _nameController.text.trim(),
        gender: _gender!.name,
        preferredGender: (_preferredGender ?? PreferredGender.all).name,
        ageRangeMin: _ageRangeMin.round(),
        ageRangeMax: _ageRangeMax.round(),
      );

      final updated = (UserService().profile ??
              UserProfile(userId: UserService().session?.userId ?? ''))
          .copyWith(
        name: _nameController.text.trim(),
        gender: _gender,
        preferredGender: _preferredGender ?? PreferredGender.all,
        ageRangeMin: _ageRangeMin.round(),
        ageRangeMax: _ageRangeMax.round(),
      );
      UserService().updateProfile(updated);
      CharactersService().invalidate();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          DCPageRoute(page: widget.destination),
        );
      }
    } catch (e) {
      debugPrint('Onboarding save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = bottomInset > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              DCProgressDots(total: _totalSteps, current: _currentStep),
              const SizedBox(height: 48),
              Expanded(child: _buildStep()),
              AnimatedPadding(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: hasKeyboard ? bottomInset - 24 : 0),
                child: _buildBottom(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep == 0)
          DCBackButton()
        else
          const SizedBox(width: 40),
        if (_currentStep == 0)
          DCHelpButton(onTap: _showHelp)
        else
          const SizedBox(width: 40),
      ],
    );
  }

  void _showHelp() {
    DCModal.show(
      context: context,
      title: 'Just a moment',
      content: Text(
        'We just need a couple of things to make this feel more personal. '
        'It only takes a moment, and you can change anything later in your profile.\n\n'
        'This is only needed for Practice and Open Chat modes — '
        'other features are available right away.',
        style: AppTypography.bodyMedium,
      ),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildPreferredGenderStep();
      case 3:
        return _buildAgeRangeStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Name ──

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What should we call you?', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        Text(
          'Just a name or nickname — whatever feels right',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 32),
        DCTextField(
          label: '',
          hint: 'e.g. Alex',
          controller: _nameController,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ── Step 2: Gender ──

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How do you identify?', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        Text(
          'This helps us understand you better',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 32),
        DCOptionCard(
          title: 'Male',
          isSelected: _gender == Gender.male,
          onTap: () => setState(() => _gender = Gender.male),
        ),
        const SizedBox(height: 12),
        DCOptionCard(
          title: 'Female',
          isSelected: _gender == Gender.female,
          onTap: () => setState(() => _gender = Gender.female),
        ),
        const SizedBox(height: 12),
        DCOptionCard(
          title: 'Other',
          isSelected: _gender == Gender.other,
          onTap: () => setState(() => _gender = Gender.other),
        ),
      ],
    );
  }

  // ── Step 3: Preferred Gender ──

  Widget _buildPreferredGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who catches your eye?', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        Text(
          'No pressure — just so we can match the right vibe',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 32),
        DCOptionCard(
          title: 'Men',
          isSelected: _preferredGender == PreferredGender.male,
          onTap: () => setState(() => _preferredGender = PreferredGender.male),
        ),
        const SizedBox(height: 12),
        DCOptionCard(
          title: 'Women',
          isSelected: _preferredGender == PreferredGender.female,
          onTap: () => setState(() => _preferredGender = PreferredGender.female),
        ),
        const SizedBox(height: 12),
        DCOptionCard(
          title: 'Everyone',
          isSelected: _preferredGender == PreferredGender.all,
          onTap: () => setState(() => _preferredGender = PreferredGender.all),
        ),
      ],
    );
  }

  // ── Step 4: Age Range ──

  Widget _buildAgeRangeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Any age preference?', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        Text(
          'Choose the range that feels right for you',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: 48),
        DCRangeSelector(
          min: 18,
          max: 60,
          currentMin: _ageRangeMin,
          currentMax: _ageRangeMax,
          onChanged: (values) {
            setState(() {
              _ageRangeMin = values.start;
              _ageRangeMax = values.end;
            });
          },
        ),
      ],
    );
  }

  // ── Bottom button ──

  Widget _buildBottom() {
    final isLast = _currentStep == _totalSteps - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DCPrimaryTextButton(
          text: isLast ? "Let's go" : 'Continue',
          onPressed: _canContinue ? _next : null,
          isLoading: _isSaving,
        ),
        if (_currentStep > 0)
          DCSecondaryTextButton(
            text: 'Back',
            onPressed: _back,
          ),
      ],
    );
  }
}
