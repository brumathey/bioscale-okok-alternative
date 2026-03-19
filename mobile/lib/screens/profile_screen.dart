import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';
import '../database/database_helper.dart';

enum _ProfileMode { list, editForm, newForm }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  int? _selectedUserId;
  String _sex = 'M';
  String _activity = 'moderate';
  _ProfileMode _mode = _ProfileMode.list;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final db = DatabaseHelper.instance;
    final users = await db.getUsers();
    final active = await db.getActiveUser();

    setState(() {
      _users = users;
      if (active != null) {
        _selectedUserId = active['id'] as int;
      }
      // On first load, if no users exist, go straight to form
      if (_isFirstLoad) {
        _isFirstLoad = false;
        if (_users.isEmpty) {
          _mode = _ProfileMode.newForm;
          _clearForm();
        }
      }
    });
  }

  void _loadUserData(Map<String, dynamic> user) {
    _nameController.text = user['name']?.toString() ?? '';
    _sex = user['sex']?.toString() ?? 'M';
    _ageController.text = (user['age'] ?? '').toString();
    _heightController.text = (user['height_cm'] ?? '').toString();
    _activity = user['activity_level']?.toString() ?? 'moderate';
    _waistController.text = user['waist_cm']?.toString() ?? '';
    _hipController.text = user['hip_cm']?.toString() ?? '';
  }

  void _clearForm() {
    _nameController.clear();
    _sex = 'M';
    _ageController.text = '30';
    _heightController.text = '170';
    _activity = 'moderate';
    _waistController.clear();
    _hipController.clear();
    _selectedUserId = null;
  }

  void _openEditForm(Map<String, dynamic> user) {
    setState(() {
      _selectedUserId = user['id'] as int;
      _loadUserData(user);
      _mode = _ProfileMode.editForm;
    });
  }

  void _openNewForm() {
    setState(() {
      _clearForm();
      _mode = _ProfileMode.newForm;
    });
  }

  Future<void> _saveProfile() async {
    final db = DatabaseHelper.instance;
    final data = {
      'name': _nameController.text.isEmpty ? 'Novo Membro' : _nameController.text,
      'sex': _sex,
      'age': int.tryParse(_ageController.text) ?? 30,
      'height_cm': double.tryParse(_heightController.text) ?? 170.0,
      'activity_level': _activity,
      'waist_cm': double.tryParse(_waistController.text),
      'hip_cm': double.tryParse(_hipController.text),
      'is_active': 1,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (_selectedUserId != null) {
      await db.updateUser(_selectedUserId!, data);
    } else {
      data['created_at'] = DateTime.now().toIso8601String();
      data['language'] = I18nService.currentLanguage;
      final id = await db.insertUser(data);
      _selectedUserId = id;
    }

    await db.setActiveUser(_selectedUserId!);

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_users.isEmpty || _mode == _ProfileMode.editForm || _mode == _ProfileMode.newForm)
                _buildForm()
              else
                _buildProfileList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title;
    if (_users.isEmpty) {
      title = I18nService.t('profile.new_profile');
    } else if (_mode == _ProfileMode.editForm) {
      title = I18nService.t('profile.title');
    } else if (_mode == _ProfileMode.newForm) {
      title = I18nService.t('profile.new_profile');
    } else {
      title = I18nService.t('profile.title');
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            if (_mode != _ProfileMode.list && _users.isNotEmpty) {
              setState(() => _mode = _ProfileMode.list);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          color: AppColors.textPrimary,
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileList() {
    return Column(
      children: [
        // Manage Profiles card
        _buildCard([
          Row(
            children: [
              const Icon(Icons.people_outline, size: 20, color: AppColors.blue),
              const SizedBox(width: 8),
              Text(
                I18nService.t('profile.manage'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._users.map((user) {
            final isActive = user['id'] == _selectedUserId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.blueLight : AppColors.bgMain,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(color: AppColors.blue.withValues(alpha: 0.3))
                    : Border.all(color: AppColors.borderLight),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: isActive ? AppColors.blue : AppColors.borderLight,
                  child: Text(
                    (user['name']?.toString() ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  user['name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          I18nService.t('profile.active_badge'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openEditForm(user),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  final db = DatabaseHelper.instance;
                  await db.setActiveUser(user['id'] as int);
                  setState(() => _selectedUserId = user['id'] as int);
                },
              ),
            );
          }),
        ]),
        const SizedBox(height: 12),

        // New Profile button
        GestureDetector(
          onTap: _openNewForm,
          child: _buildCard([
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_outlined, size: 22, color: AppColors.blue),
                const SizedBox(width: 10),
                Text(
                  I18nService.t('profile.new_profile'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return _buildCard([
      _formLabel(I18nService.t('profile.name')),
      TextField(
        controller: _nameController,
        decoration: _inputDecoration(
          hint: I18nService.t('profile.name_placeholder'),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formLabel(I18nService.t('profile.sex')),
                DropdownButtonFormField<String>(
                  key: ValueKey('sex_$_sex'),
                  initialValue: _sex,
                  items: [
                    DropdownMenuItem(value: 'M', child: Text(I18nService.t('profile.male'))),
                    DropdownMenuItem(value: 'F', child: Text(I18nService.t('profile.female'))),
                  ],
                  onChanged: (v) => setState(() => _sex = v ?? 'M'),
                  decoration: _inputDecoration(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formLabel(I18nService.t('profile.age')),
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formLabel(I18nService.t('profile.height')),
                TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formLabel(I18nService.t('profile.activity')),
                DropdownButtonFormField<String>(
                  key: ValueKey('activity_$_activity'),
                  initialValue: _activity,
                  items: [
                    DropdownMenuItem(value: 'sedentary', child: Text(I18nService.t('profile.activity_sedentary'))),
                    DropdownMenuItem(value: 'light', child: Text(I18nService.t('profile.activity_light'))),
                    DropdownMenuItem(value: 'moderate', child: Text(I18nService.t('profile.activity_moderate'))),
                    DropdownMenuItem(value: 'intense', child: Text(I18nService.t('profile.activity_intense'))),
                    DropdownMenuItem(value: 'athlete', child: Text(I18nService.t('profile.activity_athlete'))),
                  ],
                  onChanged: (v) => setState(() => _activity = v ?? 'moderate'),
                  decoration: _inputDecoration(),
                  isExpanded: true,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _formLabel(I18nService.t('profile.optional_measures')),
      Text(
        I18nService.t('profile.optional_desc'),
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _waistController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hint: I18nService.t('profile.waist')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _hipController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hint: I18nService.t('profile.hip')),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            I18nService.t('profile.save_btn'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textLabel,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.blue, width: 2),
      ),
      filled: true,
      fillColor: AppColors.bgMain,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }
}
