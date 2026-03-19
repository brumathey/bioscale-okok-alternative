import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';
import '../database/database_helper.dart';

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
  String? _message;
  bool _isSuccess = false;

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
        _loadUserData(active);
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
    await _loadUsers();

    setState(() {
      _message = I18nService.t('profile.saved')
          .replaceAll('{name}', data['name'].toString());
      _isSuccess = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _message = null);
    });
  }

  void _newProfile() {
    setState(() {
      _selectedUserId = null;
      _nameController.clear();
      _sex = 'M';
      _ageController.text = '30';
      _heightController.text = '170';
      _activity = 'moderate';
      _waistController.clear();
      _hipController.clear();
      _message = I18nService.t('profile.fill_new');
      _isSuccess = false;
    });
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
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    color: AppColors.textPrimary,
                  ),
                  Text(
                    I18nService.t('profile.title'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User selector
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formLabel(I18nService.t('profile.family_member')),
                          DropdownButtonFormField<int>(
                            key: ValueKey(_selectedUserId),
                            initialValue: _selectedUserId,
                            items: _users.map((u) {
                              return DropdownMenuItem<int>(
                                value: u['id'] as int,
                                child: Text(u['name'].toString()),
                              );
                            }).toList(),
                            onChanged: (id) async {
                              if (id == null) return;
                              final db = DatabaseHelper.instance;
                              await db.setActiveUser(id);
                              final user = await db.getActiveUser();
                              setState(() {
                                _selectedUserId = id;
                                if (user != null) _loadUserData(user);
                              });
                            },
                            decoration: _inputDecoration(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: OutlinedButton(
                        onPressed: _newProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blue,
                          side: const BorderSide(color: AppColors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(I18nService.t('profile.new')),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 12),

              // Form
              _buildCard([
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
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSuccess ? AppColors.greenLight : AppColors.blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isSuccess ? AppColors.green : AppColors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
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
