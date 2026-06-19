import 'package:intl/intl.dart';
import '../l10n.dart';

class Formatters {
  Formatters._();

  static String _locale = 'ru_RU';
  static NumberFormat _money    = NumberFormat('#,##0', 'ru_RU');
  static DateFormat _monthYear  = DateFormat('MMMM yyyy', 'ru_RU');
  static DateFormat _dayMonth   = DateFormat('d MMMM', 'ru_RU');
  static final _date            = DateFormat('yyyy-MM-dd');

  static const _ruMonthsNominative = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static void setLocale(String locale) {
    _locale = locale;
    _money     = NumberFormat('#,##0', locale);
    _monthYear = DateFormat('MMMM yyyy', locale);
    _dayMonth  = DateFormat('d MMMM', locale);
  }

  static String money(double amount, {bool signed = false, String currency = '₽'}) {
    final formatted = _money.format(amount.abs());
    if (signed) {
      final sign = amount >= 0 ? '+' : '−';
      return '$sign$formatted $currency';
    }
    return amount < 0
        ? '−$formatted $currency'
        : '$formatted $currency';
  }

  static String monthYear(DateTime date) {
    if (_locale == 'ru_RU') {
      return '${_ruMonthsNominative[date.month]} ${date.year}';
    }
    return _monthYear.format(date);
  }

  static String dayMonth(DateTime date) => _dayMonth.format(date);
  static String isoDate(DateTime date)  => _date.format(date);

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return L10n.today;
    if (diff == 1) return L10n.yesterday;
    return dayMonth(date);
  }
}

typedef Fmt = Formatters;
