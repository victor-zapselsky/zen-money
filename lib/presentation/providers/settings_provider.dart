import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n.dart';
import '../../core/utils/formatters.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String locale;
  final bool syncEnabled;
  final DateTime? lastSyncAt;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = 'ru',
    this.syncEnabled = false,
    this.lastSyncAt,
  });

  static const currency = '₽';

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? syncEnabled,
    DateTime? lastSyncAt,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        syncEnabled: syncEnabled ?? this.syncEnabled,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
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
      locale: loadedLocale,
      syncEnabled: prefs.getBool('sync_enabled') ?? false,
      lastSyncAt: prefs.getString('last_sync_at') != null
          ? DateTime.tryParse(prefs.getString('last_sync_at')!)
          : null,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
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
