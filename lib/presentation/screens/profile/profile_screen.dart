import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _localName;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name');
    final photo = prefs.getString('profile_photo');
    if (mounted) {
      setState(() {
        _localName = name;
        _photoPath = photo;
      });
    }
    // Если фото нет локально и пользователь залогинен — тянем из облака
    final hasLocal = photo != null && File(photo).existsSync();
    if (!hasLocal && AuthService.isLoggedIn) {
      await _downloadAvatarFromCloud();
    }
  }

  Future<void> _uploadAvatarToCloud(File file) async {
    if (!AuthService.isLoggedIn) return;
    final userId = AuthService.currentUser!.id;
    try {
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            '$userId/avatar.jpg',
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
    } catch (e) {
      debugPrint('[Profile] avatar upload failed: $e');
    }
  }

  Future<void> _downloadAvatarFromCloud() async {
    if (!AuthService.isLoggedIn) return;
    final userId = AuthService.currentUser!.id;
    try {
      final bytes = await Supabase.instance.client.storage
          .from('avatars')
          .download('$userId/avatar.jpg');
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/profile_avatar.jpg');
      await dest.writeAsBytes(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo', dest.path);
      if (mounted) setState(() => _photoPath = dest.path);
    } catch (_) {
      // Фото в облаке ещё нет — это нормально
    }
  }

  // ── Profile editing ────────────────────────────────────────────────────────

  Future<void> _editName() async {
    final ctrl = TextEditingController(
      text: _localName ?? (AuthService.isLoggedIn ? AuthService.userDisplayName : ''),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить имя'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Ваше имя'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', result);
      if (AuthService.isLoggedIn) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'full_name': result}),
          );
        } catch (_) {}
      }
      setState(() => _localName = result);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (picked == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/profile_avatar.jpg');
    await File(picked.path).copy(dest.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo', dest.path);
    if (mounted) setState(() => _photoPath = dest.path);
    await _uploadAvatarToCloud(dest);
  }

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
    await SyncService.clearCloudData();
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

  // ── About ──────────────────────────────────────────────────────────────────

  Future<void> _rateApp() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactDev() => _openUrl('https://t.me/zapselsky_v');

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

    final displayName = _localName ??
        (isLoggedIn ? AuthService.userDisplayName : L10n.guest);

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
                _buildAvatar(),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _editName,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.inkSoft),
                    ],
                  ),
                ),
                if (isLoggedIn && AuthService.userEmail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AuthService.userEmail!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.inkSoft),
                  ),
                ],
                if (isLoggedIn && !AuthService.isEmailVerified) ...[
                  const SizedBox(height: 10),
                  _EmailVerificationBanner(email: AuthService.userEmail ?? ''),
                ],
                if (!isLoggedIn) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: Text(L10n.loginOrRegister,
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),

                _section(L10n.appSection, [
                  _row(Icons.language_outlined, L10n.language,
                      trailing: langLabel,
                      onTap: () => _showLanguagePicker(settings.locale)),
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
                  _row(Icons.star_outline, L10n.rateApp, onTap: _rateApp),
                  _row(Icons.privacy_tip_outlined, 'Политика конфиденциальности',
                      onTap: () => _openUrl('https://victor-zapselsky.github.io/zen-money/legal/privacy_policy.html')),
                  _row(Icons.description_outlined, 'Пользовательское соглашение',
                      onTap: () => _openUrl('https://victor-zapselsky.github.io/zen-money/legal/terms.html')),
                  _row(Icons.telegram, 'Написать разработчику',
                      onTap: _contactDev),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final hasPhoto = _photoPath != null && File(_photoPath!).existsSync();
    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryGhost,
              shape: BoxShape.circle,
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(File(_photoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? null
                : (AuthService.isLoggedIn
                    ? Text(
                        AuthService.userDisplayName.isNotEmpty
                            ? AuthService.userDisplayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      )
                    : const Text('😊', style: TextStyle(fontSize: 40))),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.camera_alt, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
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

class _EmailVerificationBanner extends StatefulWidget {
  final String email;
  const _EmailVerificationBanner({required this.email});

  @override
  State<_EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<_EmailVerificationBanner> {
  bool _sent = false;
  bool _loading = false;

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      await AuthService.resendVerificationEmail();
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD966), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFB45309), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _sent ? 'Письмо отправлено' : 'Email не подтверждён',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (!_sent)
            GestureDetector(
              onTap: _loading ? null : _resend,
              child: Text(
                _loading ? '...' : 'Отправить',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }
}
