import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../../shared/widgets/dc_modal.dart';
import '../../shared/widgets/dc_buttons.dart';
import '../../shared/widgets/dc_text_field.dart';
import '../../shared/widgets/dc_dropdown.dart';

/// Модалка редактирования профиля
class ProfileEditModal extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onSave;

  const ProfileEditModal({
    super.key,
    required this.profile,
    required this.onSave,
  });

  /// Показать модалку
  static Future<UserProfile?> show({
    required BuildContext context,
    required UserProfile profile,
    required Function(UserProfile) onSave,
  }) {
    return showDialog<UserProfile>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => ProfileEditModal(
        profile: profile,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ProfileEditModal> createState() => _ProfileEditModalState();
}

class _ProfileEditModalState extends State<ProfileEditModal> {
  late TextEditingController _nameController;
  late RangeValues _ageRange;
  PreferredGender? _preferredGender;
  Gender? _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name ?? '');
    _ageRange = RangeValues(
      (widget.profile.ageRangeMin ?? 18).toDouble(),
      (widget.profile.ageRangeMax ?? 99).toDouble(),
    );
    _preferredGender = widget.profile.preferredGender;
    _gender = widget.profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    
    final updated = widget.profile.copyWith(
      name: _nameController.text.isNotEmpty ? _nameController.text : null,
      ageRangeMin: _ageRange.start.toInt(),
      ageRangeMax: _ageRange.end.toInt(),
      preferredGender: _preferredGender,
      gender: _gender,
    );
    
    await widget.onSave(updated);
    
    if (mounted) {
      Navigator.pop(context, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DCModal(
      title: 'Edit Profile',
      onClose: () => Navigator.pop(context),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DCTextField(
            label: 'Name',
            controller: _nameController,
            hint: 'Enter your name',
          ),
          const SizedBox(height: 16),
          _buildAgeRangeField(),
          const SizedBox(height: 16),
          DCDropdown<PreferredGender>(
            label: 'Preferred gender',
            value: _preferredGender,
            hint: 'Select',
            items: const [
              DCDropdownItem(value: PreferredGender.all, label: 'All'),
              DCDropdownItem(value: PreferredGender.male, label: 'Male'),
              DCDropdownItem(value: PreferredGender.female, label: 'Female'),
            ],
            onChanged: (v) => setState(() => _preferredGender = v),
          ),
          const SizedBox(height: 16),
          DCDropdown<Gender>(
            label: 'Your gender',
            value: _gender,
            hint: 'Select',
            items: const [
              DCDropdownItem(value: Gender.male, label: 'Male'),
              DCDropdownItem(value: Gender.female, label: 'Female'),
              DCDropdownItem(value: Gender.other, label: 'Other'),
            ],
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 24),
          DCPrimaryTextButton(
            text: 'Save',
            isLoading: _isSaving,
            onPressed: _save,
          ),
          const SizedBox(height: 8),
          DCSecondaryTextButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeField() {
    final currentValue = '${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}';
    final presets = [
      '18 - 99',
      '18 - 25',
      '25 - 35',
      '35 - 45',
      '45 - 55',
      '55 - 99',
    ];
    
    // Добавляем текущее значение если его нет в пресетах
    final items = presets.contains(currentValue) 
        ? presets 
        : [currentValue, ...presets];
    
    return DCDropdown<String>(
      label: 'Age range for search',
      value: currentValue,
      items: items.map((v) => DCDropdownItem(
        value: v, 
        label: v == '55 - 99' ? '55+' : v,
      )).toList(),
      onChanged: (v) {
        if (v == null) return;
        final parts = v.split(' - ');
        setState(() {
          _ageRange = RangeValues(
            double.parse(parts[0]),
            double.parse(parts[1]),
          );
        });
      },
    );
  }
}
