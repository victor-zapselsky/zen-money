import 'package:appmetrica_sdk/appmetrica_sdk.dart';

class AnalyticsService {
  // Получить API Key на appmetrica.yandex.ru → Приложения → Ключ API
  static const _apiKey = 'fbead890-a3f1-4713-a056-c56f106d94f1';

  static final _sdk = AppmetricaSdk();

  static Future<void> init() async {
    await _sdk.activate(apiKey: _apiKey, crashReporting: true);
  }

  static Future<void> _send(String name, [Map<String, dynamic>? params]) async {
    try {
      await _sdk.reportEvent(name: name, attributes: params);
    } catch (_) {
      // never crash the app due to analytics
    }
  }

  // ── User events ────────────────────────────────────────────────────────────

  static Future<void> transactionCreated({
    required String type,
    required double amount,
  }) =>
      _send('transaction_created', {
        'type': type,
        'amount_bucket': _bucket(amount),
      });

  static Future<void> transactionDeleted() => _send('transaction_deleted');

  static Future<void> accountCreated({required String type}) =>
      _send('account_created', {'type': type});

  static Future<void> budgetCreated() => _send('budget_created');

  static Future<void> userLogin() => _send('user_login');

  static Future<void> userRegister() => _send('user_register');

  // ── Navigation ─────────────────────────────────────────────────────────────

  static Future<void> screenViewed(String screen) =>
      _send('screen_viewed', {'screen': screen});

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _bucket(double amount) {
    if (amount < 100) return '<100';
    if (amount < 500) return '100-500';
    if (amount < 1000) return '500-1000';
    if (amount < 5000) return '1000-5000';
    if (amount < 10000) return '5000-10000';
    return '>10000';
  }
}
