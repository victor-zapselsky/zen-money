import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/colors.dart';
import '../../providers/settings_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _paths = ['/journal', '/accounts', '/budget', '/reports', '/profile'];
  static const _icons = [
    Icons.receipt_long_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.pie_chart_outline,
    Icons.bar_chart_outlined,
    Icons.person_outline,
  ];
  static const _activeIcons = [
    Icons.receipt_long,
    Icons.account_balance_wallet,
    Icons.pie_chart,
    Icons.bar_chart,
    Icons.person,
  ];

  List<String> _labels() => [
    L10n.navJournal,
    L10n.navAccounts,
    L10n.navBudget,
    L10n.navReports,
    L10n.navProfile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _paths.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsProvider); // rebuild on locale change
    final current = _currentIndex(context);
    final labels = _labels();
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: current,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inkSoft,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        backgroundColor: AppColors.surface,
        elevation: 8,
        onTap: (i) => context.go(_paths[i]),
        items: List.generate(
          _paths.length,
          (i) => BottomNavigationBarItem(
            icon: Icon(_icons[i]),
            activeIcon: Icon(_activeIcons[i]),
            label: labels[i],
          ),
        ),
      ),
    );
  }
}
