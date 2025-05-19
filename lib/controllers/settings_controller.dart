// lib/controllers/settings_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/app_settings.dart';
import '../services/app_settings_api.dart';

/// Singleton برای مدیریت و دسترسی به تنظیمات
class SettingsController {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  /// پس از load() این متغیر مقداردهی می‌شود
  late AppSettings settings;

  /// بارگذاری تنظیمات از سرور
  Future<void> load() async {
    try {
      // از متد صحیح fetchAppSettings در AppSettingsApi استفاده کنید
      settings = await AppSettingsApi.fetchAppSettings();
      debugPrint('>>> Loaded AppSettings: $settings');
    } catch (e, st) {
      debugPrint('Error loading AppSettings: $e\n$st');
      // در صورت خطا، یک نمونه پیش‌فرض بسازید
      settings = AppSettings.fromJson({});
    }
  }

  /// بررسی اینکه آیا یک کشور Smart تعریف شده
  bool isSmartCountry(String countryCode) {
    final code = countryCode.toLowerCase();
    return settings.smartCountries
        .map((c) => c.toLowerCase())
        .contains(code);
  }

  /// تشخیص کد کشور دستگاه (برای initializing)
  Future<String> detectUserCountryCode() async {
    final locale = WidgetsBinding.instance.window.locale;
    return locale.countryCode?.toLowerCase() ?? '';
  }
}
