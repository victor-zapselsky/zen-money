import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/services/analytics_service.dart';
import '../../providers/settings_provider.dart' show AppSettings;

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionModel? editTx;
  const AddTransactionSheet({super.key, this.editTx});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int? _categoryId;
  int? _accountId;
  DateTime _date = DateTime.now();
  bool _loading = false;

  List<AccountModel> _accounts = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _dataLoaded = false;

  bool get _isEdit => widget.editTx != null;

  String get _currency => AppSettings.currency;

  @override
  void initState() {
    super.initState();
    final initialTab = widget.editTx?.type == 'income' ? 1 : 0;
    _tabs = TabController(length: 2, vsync: this, initialIndex: initialTab);
    _tabs.addListener(() {
      setState(() {
        if (!_tabs.indexIsChanging) {
          final list = _tabs.index == 0 ? _expenseCategories : _incomeCategories;
          if (!list.any((c) => c.id == _categoryId)) _categoryId = null;
        }
      });
    });

    if (_isEdit) {
      _categoryId = widget.editTx!.categoryId;
      _accountId = widget.editTx!.accountId;
      _date = widget.editTx!.date;
      final amt = widget.editTx!.amount;
      _amountCtrl.text = amt == amt.truncateToDouble() ? amt.toInt().toString() : amt.toString();
      _noteCtrl.text = widget.editTx!.note ?? '';
    }

    _loadData();
  }

  Future<void> _loadData() async {
    final catRepo = ref.read(categoryRepositoryProvider);
    final accRepo = ref.read(accountRepositoryProvider);
    final results = await Future.wait([
      catRepo.getAll(type: 'expense'),
      catRepo.getAll(type: 'income'),
      accRepo.getAll(),
    ]);
    if (mounted) {
      setState(() {
        _expenseCategories = results[0] as List<CategoryModel>;
        _incomeCategories = results[1] as List<CategoryModel>;
        _accounts = results[2] as List<AccountModel>;
        if (!_isEdit && _accounts.isNotEmpty) _accountId = _accounts.first.id;
        _dataLoaded = true;
      });
    }
  }

  List<CategoryModel> get _currentCategories =>
      _tabs.index == 0 ? _expenseCategories : _incomeCategories;

  String get _type => _tabs.index == 0 ? 'expense' : 'income';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day,
          _date.hour, _date.minute, _date.second));
    }
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _categoryId == null || _accountId == null) return;
    setState(() => _loading = true);

    if (_isEdit) {
      final updated = widget.editTx!.copyWith(
        accountId: _accountId,
        categoryId: _categoryId,
        amount: amount,
        type: _type,
        date: _date,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      );
      await ref.read(transactionRepositoryProvider).update(updated);
    } else {
      final tx = TransactionModel(
        accountId: _accountId!,
        categoryId: _categoryId!,
        amount: amount,
        type: _type,
        date: _date,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      );
      await ref.read(transactionRepositoryProvider).insert(tx);
    }

    if (!_isEdit) {
      AnalyticsService.transactionCreated(type: _type, amount: amount);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = _currency;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.lineColor, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  _isEdit ? L10n.edit : L10n.newOperation,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkSoft,
            indicatorColor: AppColors.primary,
            tabs: [Tab(text: L10n.expenseTab), Tab(text: L10n.incomeTab)],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    border: InputBorder.none,
                    prefixText: '$currency ',
                    prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(color: AppColors.lineColor),
                const SizedBox(height: 12),
                // Date picker row
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.inkSoft),
                        const SizedBox(width: 8),
                        Text(L10n.date,
                            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                        const SizedBox(width: 8),
                        Text(Fmt.dayMonth(_date),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.lineColor),
                const SizedBox(height: 12),
                Text(L10n.category,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 72,
                  child: _currentCategories.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentCategories.length,
                          itemBuilder: (_, i) {
                            final c = _currentCategories[i];
                            final selected = _categoryId == c.id;
                            return GestureDetector(
                              onTap: () => setState(() => _categoryId = c.id),
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: selected ? AppColors.primary : AppColors.primaryGhost,
                                        shape: BoxShape.circle,
                                        border: selected
                                            ? Border.all(color: AppColors.primary, width: 2)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(c.icon, style: const TextStyle(fontSize: 20)),
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
                const SizedBox(height: 12),
                Text(L10n.account,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                const SizedBox(height: 8),
                !_dataLoaded
                    ? const LinearProgressIndicator()
                    : _accounts.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.expense.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.expense, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    L10n.noAccounts,
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.expense),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButton<int>(
                            value: _accountId,
                            isExpanded: true,
                            underline: const Divider(color: AppColors.lineColor),
                            items: _accounts.map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            )).toList(),
                            onChanged: (v) => setState(() => _accountId = v),
                          ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: L10n.note,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: AppColors.inkSoft),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_loading || (_dataLoaded && _accounts.isEmpty)) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _loading
                          ? L10n.saving
                          : (_isEdit ? L10n.saveChanges : L10n.save),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
