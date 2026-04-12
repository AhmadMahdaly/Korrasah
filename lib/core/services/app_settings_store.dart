import 'package:opration/core/services/cache_helper/cache_values.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsStore {
  const AppSettingsStore({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  String get currencyCode =>
      sharedPreferences.getString(CacheKeys.selectedCurrency) ?? 'EGP';

  bool get notificationsEnabled =>
      sharedPreferences.getBool(CacheKeys.notificationsEnabled) ?? true;

  String get currencySymbol {
    switch (currencyCode) {
      case 'SAR':
        return 'ر.س';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'EGP':
      default:
        return 'ج.م';
    }
  }

  String formatAmount(double value) =>
      '${value.toStringAsFixed(2)} $currencySymbol';
}
