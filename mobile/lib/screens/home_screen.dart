import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/i18n_service.dart';
import '../services/ble_service.dart';
import '../database/database_helper.dart';
import '../calculations/body_composition.dart';
import '../providers/providers.dart';
import '../widgets/weight_hero_card.dart';
import '../widgets/goal_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _lastMeasurement;
  Map<String, dynamic>? _prevMeasurement;
  List<Map<String, dynamic>> _allMeasurements = [];
  List<Map<String, dynamic>> _goals = [];
  bool _loading = true;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final user = await db.getActiveUser();
    if (user == null) {
      setState(() {
        _user = null;
        _loading = false;
      });
      return;
    }

    final measurements = await db.getMeasurements(user['id'] as int, limit: 100);
    var goals = await db.getGoals(user['id'] as int);

    // Auto-create goal with ideal weight (BMI 22) if none exists
    if (goals.isEmpty && user['height_cm'] != null) {
      final heightCm = (user['height_cm'] as num).toDouble();
      final idealWeight = (22.0 * (heightCm / 100.0) * (heightCm / 100.0));
      await db.insertGoal({
        'user_id': user['id'] as int,
        'metric': 'weight',
        'target_value': double.parse(idealWeight.toStringAsFixed(1)),
        'created_at': DateTime.now().toIso8601String(),
      });
      goals = await db.getGoals(user['id'] as int);
    }

    if (mounted) {
      setState(() {
        _user = user;
        _lastMeasurement = measurements.isNotEmpty ? measurements.first : null;
        _prevMeasurement = measurements.length > 1 ? measurements[1] : null;
        _allMeasurements = measurements;
        _goals = goals;
        _loading = false;
      });
    }
  }

  Future<void> _saveMeasurement(BleState state) async {
    if (_user == null || state.weightKg == null) return;

    final userId = _user!['id'] as int;
    final weightKg = state.weightKg!;
    final heightCm = (_user!['height_cm'] as num).toDouble();
    final age = (_user!['age'] as num).toInt();
    final sex = _user!['sex'] as String;
    final activity = _user!['activity_level'] as String? ?? 'sedentary';
    final waist = (_user!['waist_cm'] as num?)?.toDouble();
    final hip = (_user!['hip_cm'] as num?)?.toDouble();
    final impedance = state.impedance?.toDouble();

    final metrics = getAllMetrics(
      weightKg, heightCm, age, sex,
      impedance: impedance,
      activityLevel: activity,
      waistCm: waist,
      hipCm: hip,
    );

    final measurement = <String, dynamic>{
      'user_id': userId,
      'measured_at': DateTime.now().toIso8601String(),
      'weight_kg': metrics['weight_kg'],
      'impedance': state.impedance,
      'bmi': metrics['bmi'],
      'body_fat_percent': metrics['body_fat_percent'],
      'muscle_mass_percent': metrics['muscle_mass_percent'],
      'body_water_percent': metrics['body_water_percent'],
      'bone_mass_kg': metrics['bone_mass_kg'],
      'visceral_fat': metrics['visceral_fat'],
      'bmr': metrics['bmr'],
      'tdee': metrics['tdee'],
      'metabolic_age': metrics['metabolic_age'],
      'protein_percent': metrics['protein_percent'],
      'fat_free_mass_kg': metrics['fat_free_mass_kg'],
      'smm_kg': metrics['smm_kg'],
      'lbm_kg': metrics['lbm_kg'],
      'impedance_index': metrics['impedance_index'],
      'body_score': metrics['body_score'],
      'ideal_weight_kg': metrics['ideal_weight_kg'],
      'ffmi': metrics['ffmi'],
      'smi': metrics['smi'],
      'subcutaneous_fat_kg': metrics['subcutaneous_fat_kg'],
      'whr': metrics['whr'],
      'whtr': metrics['whtr'],
      'source': 'ble',
    };

    final db = DatabaseHelper.instance;
    final newId = await db.insertMeasurement(measurement);

    await _loadData();

    if (mounted) {
      context.push('/composition?id=$newId');
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return I18nService.t('overview.greeting_morning');
    if (hour < 18) return I18nService.t('overview.greeting_afternoon');
    return I18nService.t('overview.greeting_evening');
  }

  @override
  Widget build(BuildContext context) {
    // Listen for BLE completion to save measurement
    ref.listen<AsyncValue<BleState>>(bleStateProvider, (previous, next) {
      next.whenData((state) {
        if (state.status == BleStatus.complete && !_hasSaved) {
          _hasSaved = true;
          _saveMeasurement(state);
        }
        if (state.status == BleStatus.scanning) {
          _hasSaved = false;
        }
      });
    });

    final bleState = ref.watch(bleStateProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgMain,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_user == null) {
      return _buildNoProfile(context);
    }

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 16),

                // Weight Hero Card
                if (_lastMeasurement != null) ...[
                  WeightHeroCard(
                    weightKg: (_lastMeasurement!['weight_kg'] as num).toDouble(),
                    deltaWeight: _prevMeasurement != null
                        ? ((_lastMeasurement!['weight_kg'] as num) -
                                (_prevMeasurement!['weight_kg'] as num))
                            .toDouble()
                        : null,
                    bmi: (_lastMeasurement!['bmi'] as num?)?.toDouble(),
                    onTap: () => context.push(
                        '/composition?id=${_lastMeasurement!['id']}'),
                  ),
                ] else ...[
                  _buildNoMeasurements(),
                ],
                const SizedBox(height: 16),

                // Weigh Now Button
                _buildWeighButton(bleState),
                const SizedBox(height: 16),

                // Goal Card (show even without measurements)
                if (_goals.isNotEmpty)
                  GoalCard(
                    goal: _goals.first,
                    currentWeight: _lastMeasurement != null
                        ? (_lastMeasurement!['weight_kg'] as num).toDouble()
                        : null,
                    idealWeight: _user?['height_cm'] != null
                        ? 22.0 * ((_user!['height_cm'] as num).toDouble() / 100.0) * ((_user!['height_cm'] as num).toDouble() / 100.0)
                        : null,
                    measurements: _allMeasurements,
                    onGoalUpdated: _loadData,
                  ),
                const SizedBox(height: 16),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, ${_user?['name']?.toString().split(' ').first ?? ''}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                I18nService.t('overview.app_subtitle'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        // Language flags
        Row(
          children: I18nService.languages.entries.map((entry) {
            final isActive = entry.key == I18nService.currentLanguage;
            return GestureDetector(
              onTap: () {
                I18nService.setLanguage(entry.key);
                _saveLang(entry.key);
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? AppColors.blue : Colors.transparent,
                    width: 2,
                  ),
                  color: isActive ? AppColors.blueLight : Colors.transparent,
                ),
                child: Text(
                  entry.value['flag']!,
                  style: TextStyle(
                    fontSize: 18,
                    color: isActive ? null : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _saveLang(String lang) async {
    if (_user != null) {
      await DatabaseHelper.instance
          .updateUser(_user!['id'] as int, {'language': lang});
    }
  }

  Widget _buildNoProfile(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/ic_launcher.png',
                    width: 120,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'BioScale',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  I18nService.t('overview.create_profile_cta'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.push('/profile');
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      I18nService.t('overview.create_profile_btn'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoMeasurements() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
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
        children: [
          const Text('📊', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            I18nService.t('overview.no_measurements'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeighButton(AsyncValue<BleState> bleState) {
    String label = I18nService.t('overview.weigh_now_btn');
    Color bgColor = AppColors.blue;
    bool isDisabled = false;
    bool isComplete = false;

    bleState.whenData((state) {
      switch (state.status) {
        case BleStatus.scanning:
          label = I18nService.t('overview.step_on_scale');
          bgColor = AppColors.purple;
          isDisabled = true;
          break;
        case BleStatus.measuring:
          label = I18nService.t('overview.measuring')
              .replaceAll('{weight}', state.weightKg?.toStringAsFixed(1) ?? '...');
          bgColor = AppColors.yellow;
          isDisabled = true;
          break;
        case BleStatus.stable:
          label = I18nService.t('overview.measurement_complete')
              .replaceAll('{weight}', state.weightKg?.toStringAsFixed(2) ?? '');
          bgColor = AppColors.green;
          isDisabled = true;
          break;
        case BleStatus.complete:
          label = I18nService.t('overview.weigh_again');
          bgColor = AppColors.green;
          isComplete = true;
          break;
        case BleStatus.error:
          label = state.errorMessage ?? I18nService.t('common.error');
          bgColor = AppColors.red;
          break;
        default:
          break;
      }
    });

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isDisabled
                ? null
                : () {
                    _hasSaved = false;
                    if (isComplete) {
                      ref.read(bleServiceProvider).stopScan();
                    }
                    ref.read(bleServiceProvider).startScan();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: bgColor.withValues(alpha: 0.8),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (!isDisabled && !isComplete)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              I18nService.t('overview.weigh_hint'),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionBtn(
          icon: Icons.history,
          label: I18nService.t('overview.quick_history'),
          onTap: () async {
            await context.push('/history');
            _loadData();
          },
        ),
        const SizedBox(width: 12),
        _actionBtn(
          icon: Icons.analytics_outlined,
          label: I18nService.t('overview.quick_composition'),
          onTap: () async {
            await context.push('/composition');
            _loadData();
          },
        ),
        const SizedBox(width: 12),
        _actionBtn(
          icon: Icons.person_outline,
          label: I18nService.t('overview.quick_profile'),
          onTap: () async {
            await context.push('/profile');
            _loadData();
          },
        ),
        const SizedBox(width: 12),
        _actionBtn(
          icon: Icons.settings_outlined,
          label: I18nService.t('overview.quick_settings'),
          onTap: () async {
            await context.push('/settings');
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
            children: [
              Icon(icon, color: AppColors.blue, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
