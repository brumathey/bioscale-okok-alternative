import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/i18n_service.dart';
import 'database/database_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await I18nService.init();

  // Restore saved language from active user profile
  final user = await DatabaseHelper.instance.getActiveUser();
  if (user != null && user['language'] != null) {
    I18nService.setLanguage(user['language'] as String);
  }

  runApp(const ProviderScope(child: BioScaleApp()));
}
