import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/shell/main_shell.dart';
import '../../presentation/screens/journal/journal_screen.dart';
import '../../presentation/screens/accounts/accounts_screen.dart';
import '../../presentation/screens/budget/budget_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/onboarding',
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/journal',  builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/accounts', builder: (_, __) => const AccountsScreen()),
          GoRoute(path: '/budget',   builder: (_, __) => const BudgetScreen()),
          GoRoute(path: '/reports',  builder: (_, __) => const ReportsScreen()),
          GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
}

Future<String?> _guard(BuildContext context, GoRouterState state) async {
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('onboarded') ?? false;
  final path = state.matchedLocation;

  if (!onboarded && !path.startsWith('/onboarding') && path != '/login' && path != '/register') return '/onboarding';
  if (onboarded && path.startsWith('/onboarding'))  return '/journal';
  return null;
}
