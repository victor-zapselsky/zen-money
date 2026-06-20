import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n.dart';
import '../../core/utils/formatters.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String currency;
  final String currencyCode;
  final String locale;
  final bool syncEnabled;
  final DateTime? lastSyncAt;
  // Multiplier: db_base_amount * displayRate = amount_in_selected_currency
  final double displayRate;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.currency = '₽',
    this.currencyCode = 'RUB',
    this.locale = 'ru',
    this.syncEnabled = false,
    this.lastSyncAt,
    this.displayRate = 1.0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currency,
    String? currencyCode,
    String? locale,
    bool? syncEnabled,
    DateTime? lastSyncAt,
    double? displayRate,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        currency: currency ?? this.currency,
        currencyCode: currencyCode ?? this.currencyCode,
        locale: locale ?? this.locale,
        syncEnabled: syncEnabled ?? this.syncEnabled,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        displayRate: displayRate ?? this.displayRate,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    final loadedLocale = prefs.getString('locale') ?? 'ru';
    Formatters.setLocale(loadedLocale == 'en' ? 'en_US' : 'ru_RU');
    L10n.setLocale(loadedLocale);
    state = AppSettings(
      themeMode: ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)],
      currency: prefs.getString('currency') ?? '₽',
      currencyCode: prefs.getString('currency_code') ?? 'RUB',
      locale: loadedLocale,
      syncEnabled: prefs.getBool('sync_enabled') ?? false,
      lastSyncAt: prefs.getString('last_sync_at') != null
          ? DateTime.tryParse(prefs.getString('last_sync_at')!)
          : null,
      displayRate: prefs.getDouble('display_rate') ?? 1.0,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setCurrency(String symbol, String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', symbol);
    await prefs.setString('currency_code', code);
    state = state.copyWith(currency: symbol, currencyCode: code);
  }

  // rateNewPerOld: how many OLD currency units = 1 NEW currency unit (e.g. 90 for USD→RUB)
  Future<void> setCurrencyWithRate(String symbol, String code, double rateNewPerOld) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', symbol);
    await prefs.setString('currency_code', code);
    final newDisplayRate = state.displayRate / rateNewPerOld;
    await prefs.setDouble('display_rate', newDisplayRate);
    state = state.copyWith(currency: symbol, currencyCode: code, displayRate: newDisplayRate);
  }

  Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale);
    Formatters.setLocale(locale == 'en' ? 'en_US' : 'ru_RU');
    L10n.setLocale(locale);
    state = state.copyWith(locale: locale);
  }

  Future<void> setSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_enabled', value);
    state = state.copyWith(syncEnabled: value);
  }

  Future<void> setLastSyncAt(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_at', time.toIso8601String());
    state = state.copyWith(lastSyncAt: time);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);
