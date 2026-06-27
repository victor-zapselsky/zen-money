import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../providers/budget_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/settings_provider.dart' show AppSettings;
import '../../widgets/category_avatar.dart';
import '../../widgets/progress_bar.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final budgetsAsync = ref.watch(budgetProvider);
    const currency = AppSettings.currency;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(L10n.budget,
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

          budgetsAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
            data: (budgets) {
              if (budgets.isEmpty) {
                return const SliverFillRemaining(child: _EmptyBudget());
              }
              final totalLimit = budgets.fold(0.0, (s, b) => s + b.limitAmount);
              final totalSpent = budgets.fold(0.0, (s, b) => s + b.spentAmount);
              return SliverList(
                delegate: SliverChildListDelegate([
                  _TotalCard(limit: totalLimit, spent: totalSpent, currency: currency),
                  ...budgets.map((b) => _BudgetCard(
                    budget: b,
                    currency: currency,
                    onDelete: () async {
                      await ref.read(budgetRepositoryProvider).delete(b.id!);
                      ref.invalidate(budgetProvider);
                    },
                    onEditLimit: () => _showEditLimitDialog(context, ref, b),
                  )),
                  const SizedBox(height: 80),
                ]),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddBudget(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBudget(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(onSaved: () => ref.invalidate(budgetProvider)),
    );
  }

  void _showEditLimitDialog(BuildContext context, WidgetRef ref, BudgetModel budget) {
    final ctrl = TextEditingController(text: budget.limitAmount.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Лимит: ${budget.categoryName}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Сумма'),
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
              minimumSize: const Size(80, 36),
            ),
            onPressed: () async {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (amount == null || amount <= 0) return;
              final updated = BudgetModel(
                id: budget.id,
                categoryId: budget.categoryId,
                limitAmount: amount,
                month: budget.month,
                year: budget.year,
              );
              await ref.read(budgetRepositoryProvider).update(updated);
              ref.invalidate(budgetProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double limit;
  final double spent;
  final String currency;
  const _TotalCard({required this.limit, required this.spent, required this.currency});

  @override
  Widget build(BuildContext context) {
    final remaining = limit - spent;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.totalBudget,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                Text(Fmt.compact(limit, currency: currency),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(L10n.remaining, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              Text(Fmt.compact(remaining, currency: currency),
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: remaining < 0 ? AppColors.expense : AppColors.income)),
            ]),
          ]),
          const SizedBox(height: 12),
          ProgressBar(value: limit > 0 ? spent / limit : 0),
          const SizedBox(height: 6),
          Text(L10n.spentOf(Fmt.compact(spent, currency: currency), Fmt.compact(limit, currency: currency)),
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final String currency;
  final VoidCallback? onDelete;
  final VoidCallback? onEditLimit;
  const _BudgetCard({required this.budget, required this.currency, this.onDelete, this.onEditLimit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CategoryAvatar(
            icon: budget.categoryIcon ?? '?',
            color: budget.categoryColor ?? '#BDBDBD',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(budget.categoryName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  if (budget.isOver)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(L10n.overBudget,
                          style: const TextStyle(fontSize: 10, color: AppColors.expense)),
                    ),
                ]),
                const SizedBox(height: 8),
                ProgressBar(value: budget.percent),
                const SizedBox(height: 6),
                Row(children: [
                  Text(Fmt.compact(budget.spentAmount, currency: currency),
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                  const Spacer(),
                  Text(Fmt.compact(budget.limitAmount, currency: currency),
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.inkSoft),
            onSelected: (v) {
              if (v == 'edit') onEditLimit?.call();
              if (v == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Изменить лимит')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить', style: TextStyle(color: AppColors.expense))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📊', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text(L10n.noBudgets,
            style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Text(L10n.tapToAdd,
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
      ],
    );
  }
}

// ── Add Budget Sheet ──────────────────────────────────────────────────────────

class _AddBudgetSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddBudgetSheet({required this.onSaved});

  @override
  ConsumerState<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<_AddBudgetSheet> {
  final _amountCtrl = TextEditingController();
  int? _categoryId;
  bool _loading = false;
  bool _categoriesLoading = true;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final month = ref.read(selectedMonthProvider);
    final cats = await ref.read(categoryRepositoryProvider).getAll(type: 'expense');
    final existing = await ref.read(budgetRepositoryProvider).getForMonth(month.month, month.year);
    final existingIds = existing.map((b) => b.categoryId).toSet();
    if (mounted) {
      setState(() {
        _categories = cats.where((c) => !existingIds.contains(c.id)).toList();
        _categoriesLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _categoryId == null) return;
    setState(() => _loading = true);
    final month = ref.read(selectedMonthProvider);
    final budget = BudgetModel(
      categoryId: _categoryId!,
      limitAmount: amount,
      month: month.month,
      year: month.year,
    );
    await ref.read(budgetRepositoryProvider).insert(budget);
    AnalyticsService.budgetCreated();
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.lineColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(L10n.newBudget,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          if (_categoriesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(L10n.allCatsHaveBudget,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.inkSoft)),
              ),
            )
          else ...[
            Text(L10n.category, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  final selected = _categoryId == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = c.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.primaryGhost,
                              shape: BoxShape.circle,
                              border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(c.icon, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(height: 4),
                          Text(c.name,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: selected ? AppColors.primary : AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(L10n.limit, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                border: InputBorder.none,
                prefixText: '${AppSettings.currency} ',
                prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_loading ? L10n.saving : L10n.addBudget,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
