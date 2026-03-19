import 'dart:math';

import '../services/i18n_service.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const Map<String, double> activityFactors = {
  'sedentary': 1.2,
  'light': 1.375,
  'moderate': 1.55,
  'intense': 1.725,
  'athlete': 1.9,
};

// ---------------------------------------------------------------------------
// Rounding helper
// ---------------------------------------------------------------------------

double _r(double x, int decimals) {
  return double.parse(x.toStringAsFixed(decimals));
}

// ---------------------------------------------------------------------------
// Individual calculation functions
// ---------------------------------------------------------------------------

double calculateBmi(double weightKg, double heightCm) {
  return weightKg / pow(heightCm / 100.0, 2);
}

List<double> calculateIdealWeightRange(double heightCm) {
  final h2 = pow(heightCm / 100.0, 2).toDouble();
  return [18.5 * h2, 25.0 * h2];
}

double calculateIdealWeight(double heightCm) {
  return 22.0 * pow(heightCm / 100.0, 2).toDouble();
}

double calculateBodyFatPercent(
  double weightKg,
  double heightCm,
  int age,
  String sex, {
  double? impedance,
}) {
  double fatPercent;

  if (impedance != null && impedance > 0) {
    double num;
    if (sex == 'M') {
      num = (-0.3315 * heightCm) +
          (0.6216 * weightKg) +
          (0.0183 * age) +
          (0.0085 * impedance) +
          22.554;
    } else {
      num = (-0.3332 * heightCm) +
          (0.7509 * weightKg) +
          (0.0196 * age) +
          (0.0072 * impedance) +
          22.7193;
    }
    fatPercent = (num / weightKg) * 100;
  } else {
    final bmi = calculateBmi(weightKg, heightCm);
    if (sex == 'M') {
      fatPercent = (1.20 * bmi) + (0.23 * age) - 16.2;
    } else {
      fatPercent = (1.20 * bmi) + (0.23 * age) - 5.4;
    }
  }

  return _r(fatPercent.clamp(5.0, 45.0), 1);
}

double calculateFfm(double weightKg, double bodyFatPercent) {
  return _r(weightKg * (1 - bodyFatPercent / 100.0), 2);
}

double calculateFatMass(double weightKg, double bodyFatPercent) {
  return _r(weightKg * bodyFatPercent / 100.0, 2);
}

double? calculateImpedanceIndex(double heightCm, double? impedance) {
  if (impedance != null && impedance > 0) {
    return _r(pow(heightCm, 2).toDouble() / impedance, 2);
  }
  return null;
}

double? calculateSmm(
  double heightCm,
  int age,
  String sex,
  double? impedance,
) {
  if (impedance == null || impedance <= 0) {
    return null;
  }
  final impIdx = pow(heightCm, 2).toDouble() / impedance;
  final sexVal = sex == 'M' ? 1.0 : 0.0;
  final smm = (impIdx * 0.401) + (sexVal * 3.825) - (age * 0.071) + 5.102;
  return max(0.0, _r(smm, 2));
}

double calculateMuscleMassPercent(
  double weightKg,
  double heightCm,
  int age,
  String sex, {
  double? impedance,
}) {
  final smm = calculateSmm(heightCm, age, sex, impedance);
  if (smm != null && smm > 0) {
    return ((smm / weightKg) * 100).clamp(10.0, 65.0);
  }
  final fatPct = calculateBodyFatPercent(weightKg, heightCm, age, sex,
      impedance: impedance);
  final ffm = weightKg * (1 - fatPct / 100.0);
  final ratio = sex == 'M' ? 0.45 : 0.38;
  return _r(((ffm * ratio / weightKg) * 100).clamp(10.0, 65.0), 1);
}

double calculateLbm(double ffmKg, double boneMassKg) {
  return _r(ffmKg - boneMassKg, 2);
}

double calculateBodyWaterPercent(
  double weightKg,
  double heightCm,
  int age,
  String sex, {
  double? impedance,
}) {
  final fatPct = calculateBodyFatPercent(weightKg, heightCm, age, sex,
      impedance: impedance);
  final ffmFraction = 1 - fatPct / 100.0;
  final waterPct = ffmFraction * 73.0;
  return _r(waterPct.clamp(30.0, 75.0), 1);
}

double calculateBoneMassKg(
  double weightKg,
  double heightCm,
  int age,
  String sex, {
  double? impedance,
}) {
  final fatPct = calculateBodyFatPercent(weightKg, heightCm, age, sex,
      impedance: impedance);
  final leanKg = weightKg * (1 - fatPct / 100.0);
  double bone;
  if (sex == 'M') {
    bone = 0.046 * leanKg + 0.09 * (heightCm / 100.0);
  } else {
    bone = 0.042 * leanKg + 0.07 * (heightCm / 100.0);
  }
  return _r(bone.clamp(0.5, 5.0), 2);
}

double calculateObesityPercent(double weightKg, double heightCm,
    {String? sex}) {
  final ideal = calculateIdealWeight(heightCm);
  if (ideal <= 0) return 0.0;
  return _r(((weightKg - ideal) / ideal) * 100.0, 1);
}

double calculateBmr(double weightKg, double heightCm, int age, String sex) {
  if (sex == 'M') {
    return _r((10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5, 0);
  } else {
    return _r((10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161, 0);
  }
}

double calculateTdee(double bmr, {String activityLevel = 'sedentary'}) {
  return _r(bmr * (activityFactors[activityLevel] ?? 1.2), 0);
}

double calculateVisceralFat(
  double weightKg,
  double heightCm,
  int age,
  String sex, {
  double? impedance,
}) {
  final bmi = calculateBmi(weightKg, heightCm);
  final fatPct = calculateBodyFatPercent(weightKg, heightCm, age, sex,
      impedance: impedance);
  double vf;
  if (sex == 'M') {
    vf = 0.15 * fatPct + 0.35 * (bmi - 18.5) + 0.18 * age - 5.5;
    if (bmi > 30) {
      vf += (bmi - 30) * 0.5;
    }
  } else {
    vf = 0.12 * fatPct + 0.28 * (bmi - 18.5) + 0.14 * age - 5.0;
    if (bmi > 30) {
      vf += (bmi - 30) * 0.4;
    }
  }
  return _r(vf.clamp(1.0, 59.0), 1);
}

int calculateMetabolicAge(
  double weightKg,
  double heightCm,
  int age,
  String sex,
  double? ffmKg,
) {
  if (ffmKg == null || ffmKg <= 0) return age;

  final actualBf = ((weightKg - ffmKg) / weightKg) * 100.0;
  double idealBf;

  if (sex == 'M') {
    if (age < 30) {
      idealBf = 15.0;
    } else if (age < 40) {
      idealBf = 17.0;
    } else if (age < 50) {
      idealBf = 19.0;
    } else if (age < 60) {
      idealBf = 20.5;
    } else {
      idealBf = 22.0;
    }
  } else {
    if (age < 30) {
      idealBf = 23.0;
    } else if (age < 40) {
      idealBf = 25.0;
    } else if (age < 50) {
      idealBf = 27.0;
    } else if (age < 60) {
      idealBf = 29.0;
    } else {
      idealBf = 31.0;
    }
  }

  final bfDeviation = actualBf - idealBf;
  final ageShift = bfDeviation * 0.5;
  final metabolicAge = (age + ageShift).round();
  return metabolicAge.clamp(15, 80);
}

double calculateProteinPercent(double musclePercent) {
  return _r((musclePercent * 0.20).clamp(5.0, 25.0), 1);
}

double calculateSubcutaneousFat(double fatMassKg) {
  return _r(fatMassKg * 0.80, 2);
}

double? calculateWhr(double? waistCm, double? hipCm) {
  if (waistCm != null && hipCm != null && hipCm > 0) {
    return _r(waistCm / hipCm, 3);
  }
  return null;
}

double? calculateWhtr(double? waistCm, double heightCm) {
  if (waistCm != null && heightCm > 0) {
    return _r(waistCm / heightCm, 3);
  }
  return null;
}

double calculateFfmi(double ffmKg, double heightCm) {
  final hM = heightCm / 100.0;
  return _r(ffmKg / pow(hM, 2).toDouble(), 1);
}

double? calculateSmi(double? smmKg, double heightCm) {
  if (smmKg == null) return null;
  final hM = heightCm / 100.0;
  return _r(smmKg / pow(hM, 2).toDouble(), 1);
}

int calculateBodyScore(
  double bmi,
  double bodyFatPercent,
  double visceralFat,
  double musclePercent,
  double waterPercent,
  String sex,
) {
  final idealBf = sex == 'M' ? 17.0 : 27.0;

  final bmiS = max(0.0, 100 - (bmi - 22).abs() * 5);
  final bfS = max(0.0, 100 - (bodyFatPercent - idealBf).abs() * 3);
  final vfS = max(0.0, 100 - visceralFat * 5);
  final msS = sex == 'M'
      ? min(100.0, musclePercent * 2.2)
      : min(100.0, musclePercent * 2.8);
  final idealWater = sex == 'M' ? 57.5 : 52.5;
  final wsS = max(0.0, 100 - (waterPercent - idealWater).abs() * 3);

  final score =
      (bmiS * 0.15 + bfS * 0.30 + vfS * 0.20 + msS * 0.20 + wsS * 0.15)
          .toInt();
  return score.clamp(1, 100);
}

// ---------------------------------------------------------------------------
// getAllMetrics
// ---------------------------------------------------------------------------

Map<String, dynamic> getAllMetrics(
  double weightKg,
  double heightCm,
  int age,
  String sex, {
  double? impedance,
  String activityLevel = 'sedentary',
  double? waistCm,
  double? hipCm,
}) {
  final bmi = calculateBmi(weightKg, heightCm);
  final fatPercent = calculateBodyFatPercent(weightKg, heightCm, age, sex,
      impedance: impedance);
  final fatMassKg = calculateFatMass(weightKg, fatPercent);
  final ffmKg = calculateFfm(weightKg, fatPercent);
  final boneMassKg = calculateBoneMassKg(weightKg, heightCm, age, sex,
      impedance: impedance);
  final lbmKg = calculateLbm(ffmKg, boneMassKg);
  final smmPercent = calculateMuscleMassPercent(weightKg, heightCm, age, sex,
      impedance: impedance);

  double? smmKgRaw = calculateSmm(heightCm, age, sex, impedance);
  final double smmKg =
      smmKgRaw ?? _r(weightKg * smmPercent / 100.0, 2);

  final muscleMassKg = lbmKg;
  final double musclePercent =
      weightKg > 0 ? _r((muscleMassKg / weightKg) * 100.0, 1) : 0.0;

  final waterPercent = calculateBodyWaterPercent(weightKg, heightCm, age, sex,
      impedance: impedance);
  final waterMassKg = _r(weightKg * waterPercent / 100.0, 2);
  final proteinPercent = calculateProteinPercent(musclePercent);
  final bmr = calculateBmr(weightKg, heightCm, age, sex);
  final tdee = calculateTdee(bmr, activityLevel: activityLevel);
  final visceral = calculateVisceralFat(weightKg, heightCm, age, sex,
      impedance: impedance);
  final metabolicAge =
      calculateMetabolicAge(weightKg, heightCm, age, sex, ffmKg);
  final idealWt = calculateIdealWeight(heightCm);
  final impIdx = calculateImpedanceIndex(heightCm, impedance);
  final ffmi = calculateFfmi(ffmKg, heightCm);
  final obesityPercent =
      calculateObesityPercent(weightKg, heightCm, sex: sex);
  final smi = calculateSmi(smmKg, heightCm);
  final subcutFat = calculateSubcutaneousFat(fatMassKg);
  final bodyScore =
      calculateBodyScore(bmi, fatPercent, visceral, smmPercent, waterPercent, sex);
  final whr = calculateWhr(waistCm, hipCm);
  final whtr = calculateWhtr(waistCm, heightCm);

  return {
    'weight_kg': _r(weightKg, 2),
    'bmi': _r(bmi, 1),
    'body_fat_percent': _r(fatPercent, 1),
    'fat_mass_kg': fatMassKg,
    'fat_free_mass_kg': ffmKg,
    'muscle_mass_percent': musclePercent,
    'muscle_mass_kg': muscleMassKg,
    'smm_percent': smmPercent,
    'obesity_percent': obesityPercent,
    'body_water_percent': waterPercent,
    'water_mass_kg': waterMassKg,
    'bone_mass_kg': boneMassKg,
    'visceral_fat': visceral,
    'bmr': bmr,
    'tdee': tdee,
    'metabolic_age': metabolicAge,
    'protein_percent': proteinPercent,
    'lbm_kg': lbmKg,
    'smm_kg': smmKg,
    'impedance_index': impIdx,
    'ideal_weight_kg': _r(idealWt, 1),
    'ffmi': ffmi,
    'smi': smi,
    'subcutaneous_fat_kg': subcutFat,
    'body_score': bodyScore,
    'whr': whr,
    'whtr': whtr,
  };
}

// ---------------------------------------------------------------------------
// Body Type Analysis
// ---------------------------------------------------------------------------

/// Grid layout (4 rows x 3 cols):
/// Row 0: BMI > 24.9 | Row 1: BMI >= median(~21.7) | Row 2: BMI >= 18.5 | Row 3: BMI < 18.5
/// Col 0: fat < low | Col 1: low <= fat < high | Col 2: fat >= high
const List<List<String>> _bodyTypeGrid = [
  ['athlete_body', 'muscular_obesity', 'obesity'],
  ['muscular', 'healthy', 'slightly_overweight'],
  ['lean_muscular', 'lean', 'hidden_obesity'],
  ['skeletal_lean', 'slightly_underweight', 'empty'],
];

Map<String, dynamic> getBodyType(double bmi, double fatPercent, String sex) {
  final fatLow = sex == 'M' ? 12.0 : 22.0;
  final fatHigh = sex == 'M' ? 18.0 : 30.0;
  const bmiMedian = (18.5 + 24.9) / 2;

  int col = fatPercent < fatLow ? 0 : (fatPercent < fatHigh ? 1 : 2);
  int row;
  if (bmi > 24.9) {
    row = 0;
  } else if (bmi >= bmiMedian) {
    row = 1;
  } else if (bmi >= 18.5) {
    row = 2;
  } else {
    row = 3;
  }

  final key = _bodyTypeGrid[row][col];
  return {
    'key': key,
    'row': row,
    'col': col,
    'fat_low': fatLow,
    'fat_high': fatHigh,
  };
}

// ---------------------------------------------------------------------------
// Weight Control Data
// ---------------------------------------------------------------------------

Map<String, dynamic> getWeightControlData(
  Map<String, dynamic> metrics, String sex,
) {
  final weight = (metrics['weight_kg'] as num).toDouble();
  final idealWeight = (metrics['ideal_weight_kg'] as num).toDouble();
  final fatMassKg = (metrics['fat_mass_kg'] as num).toDouble();
  final muscleMassKg = (metrics['muscle_mass_kg'] as num).toDouble();

  final idealFatPercent = sex == 'M' ? 15.0 : 25.0;
  final idealFatMass = idealWeight * idealFatPercent / 100;
  final idealMuscleRatio = sex == 'M' ? 0.40 : 0.35;
  final idealMuscleMass = idealWeight * idealMuscleRatio;

  return {
    'weight_delta': _r(weight - idealWeight, 1),
    'fat_delta': _r(fatMassKg - idealFatMass, 1),
    'muscle_delta': _r(muscleMassKg - idealMuscleMass, 1),
    'ideal_weight': _r(idealWeight, 1),
    'ideal_fat_mass': _r(idealFatMass, 1),
    'ideal_muscle_mass': _r(idealMuscleMass, 1),
    'current_weight': _r(weight, 1),
    'current_fat': _r(fatMassKg, 1),
    'current_muscle': _r(muscleMassKg, 1),
  };
}

// ---------------------------------------------------------------------------
// ClassificationResult
// ---------------------------------------------------------------------------

class ClassificationResult {
  final double value;
  final String unit;
  final String name;
  final String label;
  final String color;
  final List<double> bounds;
  final List<String> zoneColors;
  final String desc;
  final String category;
  final double? barValue;

  const ClassificationResult({
    required this.value,
    required this.unit,
    required this.name,
    required this.label,
    required this.color,
    required this.bounds,
    this.zoneColors = const ['info', 'success', 'warning', 'danger'],
    required this.desc,
    required this.category,
    this.barValue,
  });

  Map<String, dynamic> toMap() => {
        'value': value,
        'unit': unit,
        'name': name,
        'label': label,
        'color': color,
        'bounds': bounds,
        'zoneColors': zoneColors,
        'desc': desc,
        'category': category,
        'barValue': barValue,
      };
}

// ---------------------------------------------------------------------------
// Internal classification helper
// ---------------------------------------------------------------------------

(String label, String color, int idx) _getClassification(
  double val,
  List<double> bounds,
  List<String> labels,
  List<String> colors,
) {
  if (val < bounds[0]) {
    return (labels[0], colors[0], 0);
  } else if (val < bounds[1]) {
    return (labels[1], colors[1], 1);
  } else if (val < bounds[2]) {
    return (labels[2], colors[2], 2);
  } else {
    return (labels[3], colors[3], 3);
  }
}

// ---------------------------------------------------------------------------
// getClassifications
// ---------------------------------------------------------------------------

Map<String, ClassificationResult> getClassifications(
  Map<String, dynamic> metrics,
  String sex,
  int age,
  double heightCm,
) {
  final cls = <String, ClassificationResult>{};
  final w = (metrics['weight_kg'] as num).toDouble();
  final t = I18nService.t;

  // ---- BMI ----
  {
    final val = (metrics['bmi'] as num).toDouble();
    final bounds = [18.5, 25.0, 30.0];
    final labels = [t('zone.bmi.1'), t('zone.bmi.2'), t('zone.bmi.3'), t('zone.bmi.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['bmi'] = ClassificationResult(
      value: val, unit: 'kg/m²', name: t('metric.bmi'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.bmi'), category: 'composition',
    );
  }

  // ---- Body Fat % ----
  {
    final val = (metrics['body_fat_percent'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      if (age < 40) {
        bounds = [10.0, 21.0, 26.0];
      } else if (age < 60) {
        bounds = [11.0, 22.0, 27.0];
      } else {
        bounds = [13.0, 24.0, 29.0];
      }
    } else {
      if (age < 40) {
        bounds = [20.0, 33.0, 39.0];
      } else if (age < 60) {
        bounds = [23.0, 34.0, 40.0];
      } else {
        bounds = [24.0, 36.0, 42.0];
      }
    }
    final labels = [t('zone.body_fat.1'), t('zone.body_fat.2'), t('zone.body_fat.3'), t('zone.body_fat.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['body_fat'] = ClassificationResult(
      value: val, unit: '%', name: t('metric.body_fat'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.body_fat'), category: 'composition',
    );
  }

  // ---- Fat Mass (kg) ----
  {
    final val = (metrics['fat_mass_kg'] as num).toDouble();
    List<double> bfBounds;
    if (sex == 'M') {
      if (age < 40) { bfBounds = [10.0, 21.0, 26.0]; }
      else if (age < 60) { bfBounds = [11.0, 22.0, 27.0]; }
      else { bfBounds = [13.0, 24.0, 29.0]; }
    } else {
      if (age < 40) { bfBounds = [20.0, 33.0, 39.0]; }
      else if (age < 60) { bfBounds = [23.0, 34.0, 40.0]; }
      else { bfBounds = [24.0, 36.0, 42.0]; }
    }
    final bounds = bfBounds.map((b) => _r(w * b / 100.0, 1)).toList();
    final labels = [t('zone.fat_mass.1'), t('zone.fat_mass.2'), t('zone.fat_mass.3'), t('zone.fat_mass.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['fat_mass'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.fat_mass'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.fat_mass'), category: 'composition',
    );
  }

  // ---- Subcutaneous Fat (kg) ----
  {
    final val = (metrics['subcutaneous_fat_kg'] as num).toDouble();
    List<double> bfBounds;
    if (sex == 'M') {
      if (age < 40) { bfBounds = [10.0, 21.0, 26.0]; }
      else if (age < 60) { bfBounds = [11.0, 22.0, 27.0]; }
      else { bfBounds = [13.0, 24.0, 29.0]; }
    } else {
      if (age < 40) { bfBounds = [20.0, 33.0, 39.0]; }
      else if (age < 60) { bfBounds = [23.0, 34.0, 40.0]; }
      else { bfBounds = [24.0, 36.0, 42.0]; }
    }
    final bounds = bfBounds.map((b) => _r(w * b / 100.0 * 0.80, 1)).toList();
    final labels = [t('zone.subcutaneous_fat.1'), t('zone.subcutaneous_fat.2'), t('zone.subcutaneous_fat.3'), t('zone.subcutaneous_fat.4')];
    final colors = ['success', 'warning', 'danger', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['subcutaneous_fat'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.subcutaneous_fat'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.subcutaneous_fat'), category: 'composition',
    );
  }

  // ---- Visceral Fat ----
  {
    final val = (metrics['visceral_fat'] as num).toDouble();
    final bounds = [9.0, 14.0, 15.0];
    final labels = [t('zone.visceral_fat.1'), t('zone.visceral_fat.2'), t('zone.visceral_fat.3'), t('zone.visceral_fat.4')];
    final colors = ['success', 'warning', 'danger', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['visceral_fat'] = ClassificationResult(
      value: val, unit: '', name: t('metric.visceral_fat'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.visceral_fat'), category: 'health',
    );
  }

  // ---- Muscle Mass % ----
  {
    final val = (metrics['muscle_mass_percent'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [65.0, 75.0, 85.0];
    } else {
      bounds = [60.0, 70.0, 80.0];
    }
    final labels = [t('zone.muscle_mass.1'), t('zone.muscle_mass.2'), t('zone.muscle_mass.3'), t('zone.muscle_mass.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['muscle_mass'] = ClassificationResult(
      value: val, unit: '%', name: t('metric.muscle_mass'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.muscle_mass'), category: 'composition',
    );
  }

  // ---- Muscle Mass (kg) ----
  {
    final val = (metrics['muscle_mass_kg'] as num).toDouble();
    List<double> mBounds;
    if (sex == 'M') {
      mBounds = [65.0, 75.0, 85.0];
    } else {
      mBounds = [60.0, 70.0, 80.0];
    }
    final bounds = mBounds.map((b) => _r(w * b / 100.0, 1)).toList();
    final labels = [t('zone.muscle_mass_kg.1'), t('zone.muscle_mass_kg.2'), t('zone.muscle_mass_kg.3'), t('zone.muscle_mass_kg.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['muscle_mass_kg'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.muscle_mass_kg'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.muscle_mass_kg'), category: 'composition',
    );
  }

  // ---- SMM % (Skeletal Muscle Mass %) ----
  {
    final val = (metrics['smm_percent'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [33.0, 40.0, 50.0];
    } else {
      bounds = [24.0, 31.0, 40.0];
    }
    final labels = [t('zone.smm_percent.1'), t('zone.smm_percent.2'), t('zone.smm_percent.3'), t('zone.smm_percent.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['smm_percent'] = ClassificationResult(
      value: val, unit: '%', name: t('metric.smm_percent'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.smm_percent'), category: 'composition',
    );
  }

  // ---- SMM (kg) ----
  {
    final val = (metrics['smm_kg'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [20.0, 28.0, 38.0];
    } else {
      bounds = [14.0, 20.0, 28.0];
    }
    final labels = [t('zone.smm.1'), t('zone.smm.2'), t('zone.smm.3'), t('zone.smm.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['smm'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.smm'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.smm'), category: 'composition',
    );
  }

  // ---- LBM (kg) ----
  {
    final val = (metrics['lbm_kg'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [w * 0.65, w * 0.75, w * 0.85];
    } else {
      bounds = [w * 0.60, w * 0.70, w * 0.80];
    }
    final labels = [t('zone.lbm.1'), t('zone.lbm.2'), t('zone.lbm.3'), t('zone.lbm.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['lbm'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.lbm'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.lbm'), category: 'composition',
    );
  }

  // ---- Body Water % ----
  {
    final val = (metrics['body_water_percent'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [50.0, 65.0, 80.0];
    } else {
      bounds = [45.0, 60.0, 80.0];
    }
    final labels = [t('zone.body_water.1'), t('zone.body_water.2'), t('zone.body_water.3'), t('zone.body_water.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['body_water'] = ClassificationResult(
      value: val, unit: '%', name: t('metric.body_water'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.body_water'), category: 'composition',
    );
  }

  // ---- Water Mass (kg) ----
  {
    final val = (metrics['water_mass_kg'] as num).toDouble();
    List<double> wBounds;
    if (sex == 'M') {
      wBounds = [50.0, 65.0, 80.0];
    } else {
      wBounds = [45.0, 60.0, 80.0];
    }
    final bounds = wBounds.map((b) => _r(w * b / 100.0, 1)).toList();
    final labels = [t('zone.water_mass.1'), t('zone.water_mass.2'), t('zone.water_mass.3'), t('zone.water_mass.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['water_mass'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.water_mass'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.water_mass'), category: 'composition',
    );
  }

  // ---- Bone Mass ----
  {
    final val = (metrics['bone_mass_kg'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [2.5, 3.2, 4.5];
    } else {
      bounds = [1.8, 2.5, 3.5];
    }
    final labels = [t('zone.bone_mass.1'), t('zone.bone_mass.2'), t('zone.bone_mass.3'), t('zone.bone_mass.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['bone_mass'] = ClassificationResult(
      value: val, unit: 'kg', name: t('metric.bone_mass'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.bone_mass'), category: 'composition',
    );
  }

  // ---- Protein % ----
  {
    final val = (metrics['protein_percent'] as num).toDouble();
    final bounds = [16.0, 20.0, 24.0];
    final labels = [t('zone.protein.1'), t('zone.protein.2'), t('zone.protein.3'), t('zone.protein.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['protein'] = ClassificationResult(
      value: val, unit: '%', name: t('metric.protein'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.protein'), category: 'composition',
    );
  }

  // ---- BMR ----
  {
    final val = (metrics['bmr'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [1400.0, 1700.0, 2400.0];
    } else {
      bounds = [1200.0, 1500.0, 2000.0];
    }
    final labels = [t('zone.bmr.1'), t('zone.bmr.2'), t('zone.bmr.3'), t('zone.bmr.4')];
    final colors = ['warning', 'success', 'primary', 'info'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['bmr'] = ClassificationResult(
      value: val, unit: 'kcal', name: t('metric.bmr'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.bmr'), category: 'metabolic',
    );
  }

  // ---- Obesity % ----
  {
    final val = (metrics['obesity_percent'] as num).toDouble();
    final bounds = [-10.0, 10.0, 20.0];
    final labels = [t('zone.obesity_percent.1'), t('zone.obesity_percent.2'), t('zone.obesity_percent.3'), t('zone.obesity_percent.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['obesity_percent'] = ClassificationResult(
      value: val, unit: '%', name: t('metric.obesity_percent'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.obesity_percent'), category: 'health',
    );
  }

  // ---- Body Score ----
  {
    final val = (metrics['body_score'] as num).toDouble();
    final bounds = [40.0, 60.0, 80.0];
    final labels = [t('zone.body_score.1'), t('zone.body_score.2'), t('zone.body_score.3'), t('zone.body_score.4')];
    final colors = ['danger', 'warning', 'success', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['body_score'] = ClassificationResult(
      value: val, unit: '/100', name: t('metric.body_score'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.body_score'), category: 'health',
    );
  }

  // ---- Ideal Weight ----
  {
    final iw = (metrics['ideal_weight_kg'] as num).toDouble();
    final diff = w - iw;
    final bounds = [iw - 5.0, iw, iw + 5.0];
    final iwZoneColors = ['info', 'success', 'warning', 'danger'];
    String label;
    String color;
    if (diff.abs() < 3) {
      label = t('zone.ideal_weight.2'); // Ideal
      color = 'success';
    } else if (diff < -3) {
      // Abaixo do ideal
      if (diff.abs() < 8) {
        label = t('zone.ideal_weight.1'); // Magro/Lean
        color = 'info';
      } else {
        label = t('zone.ideal_weight.4'); // Longe/Far
        color = 'danger';
      }
    } else {
      // Acima do ideal
      if (diff < 8) {
        label = t('zone.ideal_weight.3'); // Acima/Above
        color = 'warning';
      } else {
        label = t('zone.ideal_weight.4'); // Longe/Far
        color = 'danger';
      }
    }
    final desc = t('desc.ideal_weight').replaceAll('{diff}', diff.toStringAsFixed(1));
    cls['ideal_weight'] = ClassificationResult(
      value: iw, unit: 'kg', name: t('metric.ideal_weight'),
      label: label, color: color, bounds: bounds, zoneColors: iwZoneColors,
      desc: desc, category: 'health',
      barValue: w,
    );
  }

  // ---- Metabolic Age ----
  {
    final val = (metrics['metabolic_age'] as num).toDouble();
    final ageDbl = age.toDouble();
    final bounds = [ageDbl - 5, ageDbl, ageDbl + 5];
    final labels = [t('zone.metabolic_age.1'), t('zone.metabolic_age.2'), t('zone.metabolic_age.3'), t('zone.metabolic_age.4')];
    final colors = ['primary', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['metabolic_age'] = ClassificationResult(
      value: val, unit: t('common.years'), name: t('metric.metabolic_age'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.metabolic_age'), category: 'metabolic',
    );
  }

  // ---- FFMI ----
  if (metrics['ffmi'] != null) {
    final val = (metrics['ffmi'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [17.0, 20.0, 25.0];
    } else {
      bounds = [14.0, 17.0, 21.0];
    }
    final labels = [t('zone.ffmi.1'), t('zone.ffmi.2'), t('zone.ffmi.3'), t('zone.ffmi.4')];
    final colors = ['warning', 'success', 'primary', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['ffmi'] = ClassificationResult(
      value: val, unit: 'kg/m²', name: t('metric.ffmi'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.ffmi'), category: 'composition',
    );
  }

  // ---- SMI ----
  if (metrics['smi'] != null) {
    final val = (metrics['smi'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [7.0, 8.5, 10.5];
    } else {
      bounds = [5.7, 7.0, 8.5];
    }
    final labels = [t('zone.smi.1'), t('zone.smi.2'), t('zone.smi.3'), t('zone.smi.4')];
    final colors = ['danger', 'warning', 'success', 'primary'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['smi'] = ClassificationResult(
      value: val, unit: 'kg/m²', name: t('metric.smi'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.smi'), category: 'composition',
    );
  }

  // ---- WHR ----
  if (metrics['whr'] != null) {
    final val = (metrics['whr'] as num).toDouble();
    List<double> bounds;
    if (sex == 'M') {
      bounds = [0.85, 0.90, 1.00];
    } else {
      bounds = [0.75, 0.85, 0.95];
    }
    final labels = [t('zone.whr.1'), t('zone.whr.2'), t('zone.whr.3'), t('zone.whr.4')];
    final colors = ['primary', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['whr'] = ClassificationResult(
      value: val, unit: '', name: t('metric.whr'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.whr'), category: 'health',
    );
  }

  // ---- WHtR ----
  if (metrics['whtr'] != null) {
    final val = (metrics['whtr'] as num).toDouble();
    final bounds = [0.40, 0.50, 0.60];
    final labels = [t('zone.whtr.1'), t('zone.whtr.2'), t('zone.whtr.3'), t('zone.whtr.4')];
    final colors = ['info', 'success', 'warning', 'danger'];
    final (label, color, _) = _getClassification(val, bounds, labels, colors);
    cls['whtr'] = ClassificationResult(
      value: val, unit: '', name: t('metric.whtr'),
      label: label, color: color, bounds: bounds, zoneColors: colors,
      desc: t('desc.whtr'), category: 'health',
    );
  }

  return cls;
}
