import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateGateResult {
  final bool updateRequired;
  final String message;

  const UpdateGateResult({required this.updateRequired, required this.message});
}

class UpdateGateService {
  static const _defaultMessage =
      'Доступна новая версия приложения. Обновите, чтобы продолжить пользоваться Копилкой.';
  static const _rustoreUrl = 'https://www.rustore.ru/catalog/app/ru.kopilka.app';

  static String get rustoreUrl => _rustoreUrl;

  /// Fails open (returns updateRequired: false) on any error or timeout,
  /// so a backend hiccup can never lock users out of the app.
  static Future<UpdateGateResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final row = await Supabase.instance.client
          .from('app_config')
          .select('min_version_code, update_message')
          .eq('id', 1)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (row == null) return const UpdateGateResult(updateRequired: false, message: _defaultMessage);

      final minVersionCode = row['min_version_code'] as int? ?? 0;
      final message = row['update_message'] as String? ?? _defaultMessage;

      return UpdateGateResult(
        updateRequired: currentBuild < minVersionCode,
        message: message,
      );
    } catch (_) {
      return const UpdateGateResult(updateRequired: false, message: _defaultMessage);
    }
  }
}
