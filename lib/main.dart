import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database_helper.dart';
import 'data/services/analytics_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/sync_service.dart';
import 'presentation/providers/journal_provider.dart';
import 'presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('en', null);

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AnalyticsService.init();

  await Supabase.initialize(
    url: 'http://81.19.135.87:8000',
    // ignore: deprecated_member_use
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzQ4NzcyMDAwLCJleHAiOjI2ODU1NDg0MDB9'
        '.QZ9I-Qz2U1rlgB-CcSTaGigE92uA9ngW137h_fLIcF0',
  );

  runApp(const ProviderScope(child: ZenMoneyApp()));
}

class ZenMoneyApp extends ConsumerStatefulWidget {
  const ZenMoneyApp({super.key});

  @override
  ConsumerState<ZenMoneyApp> createState() => _ZenMoneyAppState();
}

class _ZenMoneyAppState extends ConsumerState<ZenMoneyApp>
    with WidgetsBindingObserver {
  late final _router = buildRouter();
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pullIfNeeded();
      _authSub = AuthService.authStateChanges.listen((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _router.go('/reset-password');
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _pullIfNeeded();
  }

  Future<void> _pullIfNeeded() async {
    final settings = ref.read(settingsProvider);
    if (!settings.syncEnabled || !AuthService.isLoggedIn) return;
    final hadData =
        await SyncService.pullFromCloud(ref.read(databaseHelperProvider));
    if (hadData) {
      ref.invalidate(journalProvider);
      ref.invalidate(monthlySummaryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale == 'en' ? const Locale('en') : const Locale('ru');
    return MaterialApp.router(
      title: 'Копилка',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: locale,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
