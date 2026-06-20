import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/settings_provider.dart' show AppSettings;

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final totalAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(L10n.accounts,
                style: const TextStyle(
                    color: AppColors.inkDark, fontWeight: FontWeight.w700)),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.totalBalance,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  totalAsync.when(
                    loading: () => const Text('—',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700)),
                    error: (_, __) => const SizedBox(),
                    data: (t) => Text(Fmt.money(t, currency: AppSettings.currency),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),

          accountsAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverFillRemaining(child: Center(child: Text('$e'))),
            data: (accounts) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _AccountCard(
                    account: accounts[i],
                    onDelete: () async {
                      await ref
                          .read(accountRepositoryProvider)
                          .delete(accounts[i].id!);
                      ref.invalidate(accountsProvider);
                      ref.invalidate(totalBalanceProvider);
                      ref.invalidate(journalProvider);
                      ref.invalidate(monthlySummaryProvider);
                    },
                  ),
                  childCount: accounts.length,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddAccount(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddAccount(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAccountSheet(onSaved: () {
        ref.invalidate(accountsProvider);
        ref.invalidate(totalBalanceProvider);
      }),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback? onDelete;
  const _AccountCard({required this.account, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(account.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(account.icon,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(account.typeLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.money(account.balance, currency: AppSettings.currency),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Text(L10n.delete,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkSoft)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddAccountSheet({required this.onSaved});

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController();
  String _type = 'debit';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.newAccount,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _label(L10n.name),
          TextField(
            controller: _nameCtrl,
            decoration: _inputDec('Карта / Наличные'),
          ),
          const SizedBox(height: 12),
          _label(L10n.initialBalance),
          TextField(
            controller: _balCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDec('0'),
          ),
          const SizedBox(height: 12),
          _label(L10n.type),
          DropdownButton<String>(
            value: _type,
            isExpanded: true,
            underline: const Divider(color: AppColors.lineColor),
            onChanged: (v) => setState(() => _type = v!),
            items: [
              DropdownMenuItem(value: 'debit', child: Text(L10n.debitCard)),
              DropdownMenuItem(value: 'cash', child: Text(L10n.cash)),
              DropdownMenuItem(value: 'credit', child: Text(L10n.creditCard)),
              DropdownMenuItem(value: 'savings', child: Text(L10n.savings)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                final bal = double.tryParse(_balCtrl.text.replaceAll(',', '.')) ?? 0;
                if (name.isEmpty) return;
                final model = AccountModel(
                  name: name,
                  type: _type,
                  balance: bal,
                  color: '#433DCB',
                  icon: name.isNotEmpty ? name[0].toUpperCase() : 'А',
                  createdAt: DateTime.now(),
                );
                await ref.read(accountRepositoryProvider).insert(model);
                AnalyticsService.accountCreated(type: _type);
                widget.onSaved();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(L10n.add,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
}
