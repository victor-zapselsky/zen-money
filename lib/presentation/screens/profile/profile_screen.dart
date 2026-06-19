import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/sync_service.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/settings_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _syncing = false;

  // ── Sync ────────────────────────────────────────────────────────────────────

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final db = ref.read(databaseHelperProvider);
      await SyncService.pushToCloud(db);
      await ref.read(settingsProvider.notifier).setLastSyncAt(DateTime.now());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные синхронизированы с облаком')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка синхронизации: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _toggleSync(bool value) async {
    if (value && !AuthService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Войдите в аккаунт, чтобы включить синхронизацию')),
      );
      return;
    }
    await ref.read(settingsProvider.notifier).setSyncEnabled(value);
    if (value && mounted) {
      await _syncNow();
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await AuthService.signOut();
    await ref.read(settingsProvider.notifier).setSyncEnabled(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarded');
    if (mounted) context.go('/onboarding');
  }

  // ── Data management ────────────────────────────────────────────────────────

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить данные?'),
        content: const Text(
            'Все счета, транзакции и бюджеты будут удалены. Категории останутся.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(databaseHelperProvider).clearAllData();
    ref.invalidate(accountsProvider);
    ref.invalidate(totalBalanceProvider);
    ref.invalidate(journalProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.invalidate(budgetProvider);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Данные очищены')));
    }
  }

  Future<void> _exportData() async {
    try {
      final txRepo = ref.read(transactionRepositoryProvider);
      final accRepo = ref.read(accountRepositoryProvider);
      final accounts = await accRepo.getAll();
      final transactions = await txRepo.getAll();
      final data = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'accounts': accounts.map((a) => a.toMap()).toList(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/zen_money_backup.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Экспорт выполнен'),
            content: Text('Файл сохранён:\n${file.path}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
      }
    }
  }

  Future<void> _importData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/zen_money_backup.json');
      if (!file.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Файл резервной копии не найден. Сначала выполните экспорт.')),
          );
        }
        return;
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Импорт данных'),
          content: const Text(
              'Текущие данные будут заменены данными из резервной копии. Продолжить?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Импорт'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final db = await ref.read(databaseHelperProvider).database;
      await db.transaction((txn) async {
        await txn.delete('transactions');
        await txn.delete('accounts');
        for (final a in (data['accounts'] as List? ?? [])) {
          await txn.insert('accounts', Map<String, dynamic>.from(a as Map));
        }
        for (final t in (data['transactions'] as List? ?? [])) {
          await txn.insert('transactions', Map<String, dynamic>.from(t as Map));
        }
      });
      ref.invalidate(accountsProvider);
      ref.invalidate(totalBalanceProvider);
      ref.invalidate(journalProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(budgetProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Данные успешно импортированы')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка импорта: $e')));
      }
    }
  }

  String _formatSyncTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    final date = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date в $time';
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final isLoggedIn = user != null;
    final langLabel = settings.locale == 'en' ? 'English' : 'Русский';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(L10n.profile,
                style: const TextStyle(
                    color: AppColors.inkDark, fontWeight: FontWeight.w700)),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildAvatar(isLoggedIn),
                const SizedBox(height: 12),
                Text(
                  isLoggedIn ? AuthService.userDisplayName : L10n.guest,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (isLoggedIn && AuthService.userEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AuthService.userEmail!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft),
                  ),
                ],
                if (!isLoggedIn) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(L10n.loginOrRegister,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),

                _section(L10n.appSection, [
                  _row(Icons.language_outlined, L10n.language,
                      trailing: langLabel,
                      onTap: () =>
                          _showLanguagePicker(settings.locale)),
                  _row(Icons.attach_money_outlined, L10n.currency,
                      trailing: '${settings.currency} ${settings.currencyCode}',
                      onTap: () => _showCurrencyPicker(settings.currency)),
                ]),
                const SizedBox(height: 12),

                _section(L10n.syncSection, [
                  _switchRow(
                    Icons.cloud_sync_outlined,
                    L10n.cloudSync,
                    value: settings.syncEnabled,
                    onChanged: _toggleSync,
                    subtitle: isLoggedIn ? null : L10n.signInToEnable,
                  ),
                  if (settings.syncEnabled && isLoggedIn) ...[
                    _row(
                      _syncing ? Icons.hourglass_top_outlined : Icons.sync,
                      _syncing ? L10n.syncing : L10n.syncNow,
                      onTap: _syncing ? null : _syncNow,
                    ),
                    _row(
                      Icons.access_time_outlined,
                      L10n.lastSync,
                      trailing: settings.lastSyncAt != null
                          ? _formatSyncTime(settings.lastSyncAt!)
                          : L10n.never,
                    ),
                  ],
                ]),
                const SizedBox(height: 12),

                _section(L10n.dataSection, [
                  _row(Icons.download_outlined, L10n.exportData,
                      onTap: _exportData),
                  _row(Icons.upload_outlined, L10n.importData,
                      onTap: _importData),
                  _row(Icons.delete_outline, L10n.clearData,
                      onTap: _clearData, color: AppColors.expense),
                ]),
                const SizedBox(height: 12),

                _section(L10n.aboutSection, [
                  _row(Icons.info_outline, L10n.version, trailing: '1.0.0'),
                  _row(Icons.star_outline, L10n.rateApp, onTap: () {}),
                  _row(Icons.feedback_outlined, L10n.contactUs, onTap: () {}),
                ]),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lineColor),
                      foregroundColor: AppColors.inkSoft,
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Text(L10n.logout,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showLanguagePicker(String current) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Язык'),
        children: [
          _langOption(ctx, 'ru', '🇷🇺  Русский', current),
          _langOption(ctx, 'en', '🇬🇧  English', current),
        ],
      ),
    );
  }

  Widget _langOption(
      BuildContext ctx, String locale, String label, String current) {
    return SimpleDialogOption(
      onPressed: () {
        ref.read(settingsProvider.notifier).setLocale(locale);
        Navigator.pop(ctx);
      },
      child: Row(children: [
        Expanded(child: Text(label)),
        if (current == locale)
          const Icon(Icons.check, color: AppColors.primary, size: 18),
      ]),
    );
  }

  void _showCurrencyPicker(String current) {
    const currencies = [
      ('₽', 'RUB', '🇷🇺  Рубль (₽)'),
      ('\$', 'USD', '🇺🇸  Доллар (\$)'),
      ('€', 'EUR', '🇪🇺  Евро (€)'),
      ('£', 'GBP', '🇬🇧  Фунт (£)'),
      ('¥', 'JPY', '🇯🇵  Иена (¥)'),
      ('₸', 'KZT', '🇰🇿  Тенге (₸)'),
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Валюта'),
        children: currencies.map((c) {
          final (symbol, code, label) = c;
          return SimpleDialogOption(
            onPressed: () {
              ref.read(settingsProvider.notifier).setCurrency(symbol, code);
              Navigator.pop(ctx);
            },
            child: Row(children: [
              Expanded(child: Text(label)),
              if (current == symbol)
                const Icon(Icons.check, color: AppColors.primary, size: 18),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildAvatar(bool isLoggedIn) {
    if (isLoggedIn) {
      final initials = (AuthService.userDisplayName.isNotEmpty)
          ? AuthService.userDisplayName[0].toUpperCase()
          : '?';
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(initials,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
          color: AppColors.primaryGhost, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Text('😊', style: TextStyle(fontSize: 40)),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                    letterSpacing: 0.8)),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label,
      {String? trailing, VoidCallback? onTap, Color? color}) {
    final fg = color ?? AppColors.inkDark;
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, color: fg, size: 20),
      title: Text(label, style: TextStyle(color: fg, fontSize: 14)),
      trailing: trailing != null
          ? Text(trailing,
              style:
                  const TextStyle(color: AppColors.inkSoft, fontSize: 13))
          : onTap != null
              ? const Icon(Icons.chevron_right,
                  color: AppColors.inkSoft, size: 18)
              : null,
    );
  }

  Widget _switchRow(
    IconData icon,
    String label, {
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.inkDark, size: 20),
      title: Text(label,
          style: const TextStyle(color: AppColors.inkDark, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style:
                  const TextStyle(color: AppColors.inkSoft, fontSize: 12))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primaryGhost,
      ),
    );
  }
}
