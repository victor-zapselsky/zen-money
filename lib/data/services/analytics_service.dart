import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static const _apiKey = 'fbead890-a3f1-4713-a056-c56f106d94f1';

  static Future<void> init() async {
    try {
      await AppMetrica.activate(AppMetricaConfig(_apiKey, crashReporting: true));
    } catch (e) {
      debugPrint('[Analytics] init error: $e');
    }
  }

  static Future<void> _send(String name, [Map<String, Object>? params]) async {
    try {
      if (params != null) {
        await AppMetrica.reportEventWithMap(name, params);
      } else {
        await AppMetrica.reportEvent(name);
      }
    } catch (e) {
      debugPrint('[Analytics] error sending "$name": $e');
    }
  }

  static Future<void> transactionCreated({required String type, required double amount}) =>
      _send('transaction_created', <String, Object>{'type': type, 'amount_bucket': _bucket(amount)});

  static Future<void> transactionDeleted() => _send('transaction_deleted');

  static Future<void> accountCreated({required String type}) =>
      _send('account_created', <String, Object>{'type': type});

  static Future<void> budgetCreated() => _send('budget_created');

  static Future<void> userLogin() => _send('user_login');

  static Future<void> userRegister() => _send('user_register');

  static Future<void> screenViewed(String screen) =>
      _send('screen_viewed', <String, Object>{'screen': screen});

  static String _bucket(double amount) {
    if (amount < 100) return '<100';
    if (amount < 500) return '100-500';
    if (amount < 1000) return '500-1000';
    if (amount < 5000) return '1000-5000';
    if (amount < 10000) return '5000-10000';
    return '>10000';
  }
}
