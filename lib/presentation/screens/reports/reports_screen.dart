import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/reports_provider.dart';
import '../../providers/settings_provider.dart' show AppSettings;
import '../../widgets/category_avatar.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period      = ref.watch(reportPeriodProvider);
    final type        = ref.watch(reportTypeProvider);
    final chartAsync  = ref.watch(chartDataProvider);
    final catAsync    = ref.watch(categorySpendingProvider);
    const currency    = AppSettings.currency;
    final selectedKey = ref.watch(selectedPeriodKeyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text(L10n.reports,
                style: const TextStyle(
                    color: AppColors.inkDark, fontWeight: FontWeight.w700)),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _Filters(period: period, type: type),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChartLegend(type: type),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: chartAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox(),
                          data: (data) => _BarChartSection(
                            data: data,
                            period: period,
                            type: type,
                            selectedKey: selectedKey,
                            onKeySelected: (key) => ref
                                .read(selectedPeriodKeyProvider.notifier)
                                .state = key,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(L10n.byCategory,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ),
                          const _PeriodNav(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      catAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox(),
                        data: (cats) {
                          if (cats.isEmpty) {
                            return SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(L10n.noData,
                                      style: const TextStyle(
                                          color: AppColors.inkSoft)),
                                ),
                              ),
                            );
                          }
                          final total = cats.fold<double>(
                              0,
                              (s, c) =>
                                  s + (c['total'] as num).toDouble());
                          return Column(
                            children: cats.map((c) {
                              final amount =
                                  (c['total'] as num).toDouble();
                              final pct =
                                  total > 0 ? amount / total : 0.0;
                              return _CategoryRow(
                                icon: c['icon'] as String? ?? '?',
                                color:
                                    c['color'] as String? ?? '#BDBDBD',
                                name: c['name'] as String? ?? '',
                                amount: amount,
                                percent: pct,
                                currency: currency,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
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

// ─── Filters ──────────────────────────────────────────────────────────────────

class _Filters extends ConsumerWidget {
  final ReportPeriod period;
  final ReportType type;
  const _Filters({required this.period, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: ReportType.values.map((t) {
              final sel = t == type;
              final label = t == ReportType.total
                  ? L10n.total
                  : t == ReportType.income
                      ? L10n.income
                      : L10n.expenses;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      ref.read(reportTypeProvider.notifier).state = t,
                  child: _FilterChip(label: label, selected: sel),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ReportPeriod.values.map((p) {
                final sel = p == period;
                final label = p == ReportPeriod.days
                    ? L10n.byDay
                    : p == ReportPeriod.weeks
                        ? L10n.byWeek
                        : p == ReportPeriod.months
                            ? L10n.byMonth
                            : L10n.byYear;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(reportPeriodProvider.notifier).state = p;
                      ref.read(selectedPeriodKeyProvider.notifier).state =
                          defaultKeyForPeriod(p);
                    },
                    child: _FilterChip(label: label, selected: sel),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            selected ? null : Border.all(color: AppColors.lineColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.inkSoft,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Period nav ───────────────────────────────────────────────────────────────

class _PeriodNav extends ConsumerWidget {
  const _PeriodNav();

  static const _monthNames = [
    '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  static String _fmtKey(ReportPeriod period, String key) {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.days:
        final d = DateTime.tryParse(key);
        if (d == null) return key;
        final s = Fmt.dayMonth(d);
        return d.year != now.year ? '$s ${d.year}' : s;
      case ReportPeriod.weeks:
        final start = DateTime.tryParse(key);
        if (start == null) return key;
        final end = start.add(const Duration(days: 6));
        final sm = _monthNames[start.month];
        final em = _monthNames[end.month];
        final yr = end.year != now.year ? ' ${end.year}' : '';
        if (start.month == end.month) {
          return '${start.day}–${end.day} $em$yr';
        }
        return '${start.day} $sm – ${end.day} $em$yr';
      case ReportPeriod.months:
        final parts = key.split('-');
        if (parts.length < 2) return key;
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return Fmt.monthYear(d);
      case ReportPeriod.years:
        return key;
    }
  }

  static String _shiftKey(ReportPeriod period, String key, int delta) {
    switch (period) {
      case ReportPeriod.days:
        final d = DateTime.tryParse(key);
        if (d == null) return key;
        final nd = d.add(Duration(days: delta));
        return '${nd.year}-${nd.month.toString().padLeft(2, '0')}-${nd.day.toString().padLeft(2, '0')}';
      case ReportPeriod.weeks:
        final d = DateTime.tryParse(key);
        if (d == null) return key;
        final nd = d.add(Duration(days: delta * 7));
        return '${nd.year}-${nd.month.toString().padLeft(2, '0')}-${nd.day.toString().padLeft(2, '0')}';
      case ReportPeriod.months:
        final parts = key.split('-');
        if (parts.length < 2) return key;
        final nd = DateTime(int.parse(parts[0]), int.parse(parts[1]) + delta);
        return '${nd.year}-${nd.month.toString().padLeft(2, '0')}';
      case ReportPeriod.years:
        final y = int.tryParse(key) ?? DateTime.now().year;
        return '${y + delta}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final key    = ref.watch(selectedPeriodKeyProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => ref.read(selectedPeriodKeyProvider.notifier).state =
              _shiftKey(period, key, -1),
          child: const Icon(Icons.chevron_left,
              color: AppColors.inkDark, size: 20),
        ),
        Text(
          _fmtKey(period, key),
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13),
        ),
        GestureDetector(
          onTap: () => ref.read(selectedPeriodKeyProvider.notifier).state =
              _shiftKey(period, key, 1),
          child: const Icon(Icons.chevron_right,
              color: AppColors.inkDark, size: 20),
        ),
      ],
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  final ReportType type;
  const _ChartLegend({required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (type == ReportType.total || type == ReportType.income)
          _LegendDot(color: AppColors.income, label: L10n.income),
        if (type == ReportType.total) const SizedBox(width: 16),
        if (type == ReportType.total || type == ReportType.expense)
          _LegendDot(color: AppColors.expense, label: L10n.expenses),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      ],
    );
  }
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _BarChartSection extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final ReportPeriod period;
  final ReportType type;
  final String selectedKey;
  final ValueChanged<String> onKeySelected;

  const _BarChartSection({
    required this.data,
    required this.period,
    required this.type,
    required this.selectedKey,
    required this.onKeySelected,
  });

  static const _monthAbbr = [
    '', 'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
          child: Text(L10n.noData,
              style: const TextStyle(color: AppColors.inkSoft)));
    }

    final screenW  = MediaQuery.of(context).size.width;
    final isDouble = type == ReportType.total;
    final barW     = isDouble ? 10.0 : 16.0;
    final groupW   = isDouble ? 30.0 : 22.0;
    final chartW   = math.max(screenW - 72.0, data.length * groupW);

    double maxVal = 0;
    for (final d in data) {
      final inc = (d['income'] as num? ?? 0).toDouble();
      final exp = (d['expense'] as num? ?? 0).toDouble();
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }
    final effectiveMax = maxVal < 1 ? 1000.0 : maxVal * 1.3;

    int labelEvery = 1;
    if (data.length > 40) {
      labelEvery = 8;
    } else if (data.length > 20) {
      labelEvery = 4;
    } else if (data.length > 12) {
      labelEvery = 2;
    }

    final hasMatch = data.any((r) => _keyForRow(r, period) == selectedKey);

    final groups = data.asMap().entries.map((e) {
      final inc = (e.value['income'] as num? ?? 0).toDouble();
      final exp = (e.value['expense'] as num? ?? 0).toDouble();
      final rods = <BarChartRodData>[];

      final rowKey    = _keyForRow(e.value, period);
      final isSelected = !hasMatch || rowKey == selectedKey;
      final alpha     = isSelected ? 1.0 : 0.28;

      if (type == ReportType.total || type == ReportType.income) {
        rods.add(BarChartRodData(
          toY: inc,
          color: AppColors.income.withValues(alpha: alpha),
          width: barW,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: !isDouble
              ? BackgroundBarChartRodData(
                  show: true,
                  toY: effectiveMax,
                  color: AppColors.income.withValues(alpha: isSelected ? 0.06 : 0.02),
                )
              : BackgroundBarChartRodData(show: false),
        ));
      }
      if (type == ReportType.total || type == ReportType.expense) {
        rods.add(BarChartRodData(
          toY: exp,
          color: AppColors.expense.withValues(alpha: alpha),
          width: barW,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: !isDouble
              ? BackgroundBarChartRodData(
                  show: true,
                  toY: effectiveMax,
                  color: AppColors.expense.withValues(alpha: isSelected ? 0.06 : 0.02),
                )
              : BackgroundBarChartRodData(show: false),
        ));
      }

      return BarChartGroupData(
        x: e.key,
        barsSpace: isDouble ? 3 : 0,
        barRods: rods,
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartW,
        child: BarChart(
          BarChartData(
            maxY: effectiveMax,
            groupsSpace: isDouble ? 8 : 6,
            barGroups: groups,
            barTouchData: BarTouchData(
              touchCallback: (event, response) {
                if (!event.isInterestedForInteractions) return;
                final index = response?.spot?.touchedBarGroupIndex;
                if (index != null && index >= 0 && index < data.length) {
                  onKeySelected(_keyForRow(data[index], period));
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.inkDark,
                getTooltipItem: (group, _, rod, rodIndex) {
                  final prefix = isDouble
                      ? (rodIndex == 0
                          ? '${L10n.income}: '
                          : '${L10n.expenses}: ')
                      : '';
                  return BarTooltipItem(
                    '$prefix${_fmtShort(rod.toY)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: effectiveMax / 4,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.lineColor,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: effectiveMax / 4,
                  getTitlesWidget: (v, _) => v == 0
                      ? const SizedBox()
                      : Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            _fmtShort(v),
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.inkSoft),
                            textAlign: TextAlign.right,
                          ),
                        ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox();
                    }
                    if (i % labelEvery != 0) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getLabel(data[i], period),
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.inkSoft),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _keyForRow(Map<String, dynamic> row, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.days:    return row['day'] as String? ?? '';
      case ReportPeriod.weeks:   return row['week_start'] as String? ?? '';
      case ReportPeriod.months:  return row['month'] as String? ?? '';
      case ReportPeriod.years:   return row['year'] as String? ?? '';
    }
  }

  static String _getLabel(Map<String, dynamic> row, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.days:
        final d = DateTime.tryParse(row['day'] as String? ?? '');
        return d != null ? '${d.day}/${d.month}' : '';
      case ReportPeriod.weeks:
        final d = DateTime.tryParse(row['week_start'] as String? ?? '');
        return d != null ? '${d.day}/${d.month}' : '';
      case ReportPeriod.months:
        final s = row['month'] as String? ?? '';
        final parts = s.split('-');
        if (parts.length < 2) return '';
        final m = int.tryParse(parts[1]) ?? 0;
        return (m >= 1 && m <= 12) ? _monthAbbr[m] : '';
      case ReportPeriod.years:
        return row['year'] as String? ?? '';
    }
  }

  static String _fmtShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}М';
    if (v >= 1000) return '${(v / 1000).round()}К';
    return v.round().toString();
  }
}

// ─── Category row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String icon;
  final String color;
  final String name;
  final double amount;
  final double percent;
  final String currency;
  const _CategoryRow({
    required this.icon,
    required this.color,
    required this.name,
    required this.amount,
    required this.percent,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CategoryAvatar(icon: icon, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 14))),
                  Text(Fmt.compact(amount, currency: currency),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor: AppColors.lineColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _parseColor(color)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('${(percent * 100).round()}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.inkSoft)),
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
