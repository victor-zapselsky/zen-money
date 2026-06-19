import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import 'category_avatar.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final String currency;

  const TransactionTile({
    super.key,
    required this.tx,
    this.onDelete,
    this.onEdit,
    this.currency = '₽',
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onEdit,
      leading: CategoryAvatar(
        icon: tx.categoryIcon ?? '?',
        color: tx.categoryColor ?? '#BDBDBD',
      ),
      title: Text(
        tx.categoryName ?? 'Без категории',
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: tx.note != null || tx.accountName != null
          ? Text(
              tx.note ?? tx.accountName ?? '',
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Fmt.money(tx.signedAmount, signed: true, currency: currency),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: tx.isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.inkSoft),
              onSelected: (v) {
                if (v == 'edit') onEdit?.call();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить', style: TextStyle(color: AppColors.expense)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
