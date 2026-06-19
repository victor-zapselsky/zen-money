import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final asyncAuth = ref.watch(authStateProvider);
  return asyncAuth.when(
    data: (state) => state.session?.user,
    loading: () => AuthService.currentUser,
    error: (_, __) => null,
  );
});
