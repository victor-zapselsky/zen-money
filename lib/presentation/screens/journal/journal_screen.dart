import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../providers/journal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/transaction_tile.dart';
import 'add_transaction_sheet.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final txAsync = ref.watch(journalProvider);
    final summaryAsync = ref.watch(displayMonthlySummaryProvider);
    final currency = ref.watch(settingsProvider).currency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(L10n.journal,
                style: const TextStyle(color: AppColors.inkDark, fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.inkDark),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(month.year, month.month - 1),
              ),
              TextButton(
                onPressed: () {},
                child: Text(Fmt.monthYear(month),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.inkDark),
                onPressed: () => ref.read(selectedMonthProvider.notifier).state =
                    DateTime(month.year, month.month + 1),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: summaryAsync.when(
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox(),
              data: (s) => _SummaryCard(
                income: s['income'] ?? 0,
                expense: s['expense'] ?? 0,
                currency: currency,
              ),
            ),
          ),

          txAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Ошибка: $e'))),
            data: (txs) => txs.isEmpty
                ? const SliverFillRemaining(child: _EmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final tx = txs[i];
                        return Column(
                          children: [
                            if (i == 0 || !_sameDay(txs[i - 1].date, tx.date))
                              _DateHeader(date: tx.date),
                            TransactionTile(
                              tx: tx,
                              currency: tx.accountCurrency ?? currency,
                              onEdit: () async {
                                final changed = await showModalBottomSheet<bool>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => AddTransactionSheet(editTx: tx),
                                );
                                if (changed == true) {
                                  ref.invalidate(journalProvider);
                                  ref.invalidate(monthlySummaryProvider);
                                }
                              },
                              onDelete: () async {
                                await ref.read(transactionRepositoryProvider).delete(tx.id!);
                                ref.invalidate(journalProvider);
                                ref.invalidate(monthlySummaryProvider);
                              },
                            ),
                          ],
                        );
                      },
                      childCount: txs.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          final added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AddTransactionSheet(),
          );
          if (added == true) {
            ref.invalidate(journalProvider);
            ref.invalidate(monthlySummaryProvider);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;
  final String currency;
  const _SummaryCard({required this.income, required this.expense, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(label: L10n.income, amount: income, color: AppColors.income, currency: currency),
          ),
          Container(width: 1, height: 40, color: AppColors.lineColor),
          Expanded(
            child: _SummaryItem(label: L10n.expenses, amount: expense, color: AppColors.expense, currency: currency),
          ),
          Container(width: 1, height: 40, color: AppColors.lineColor),
          Expanded(
            child: _SummaryItem(
                label: L10n.balance, amount: income - expense, color: AppColors.inkDark, currency: currency),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currency;
  const _SummaryItem({required this.label, required this.amount, required this.color, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
        const SizedBox(height: 4),
        Text(Fmt.money(amount, currency: currency),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        Fmt.relativeDate(date),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🗒', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(L10n.noTransactions,
            style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
      ],
    );
  }
}
