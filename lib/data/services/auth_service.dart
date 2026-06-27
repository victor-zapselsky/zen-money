import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get _sb => Supabase.instance.client;

  static User? get currentUser => _sb.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges => _sb.auth.onAuthStateChange;

  static String? get userEmail => currentUser?.email;
  static String? get userName =>
      currentUser?.userMetadata?['full_name'] as String?;
  static String get userDisplayName =>
      userName ?? userEmail?.split('@').first ?? 'Пользователь';

  static Future<AuthResponse> signIn(String email, String password) =>
      _sb.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp(
    String email,
    String password, {
    String? name,
  }) =>
      _sb.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'full_name': name} : null,
      );

  static bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  static Future<void> signOut() => _sb.auth.signOut();

  static Future<void> resetPassword(String email) =>
      _sb.auth.resetPasswordForEmail(
        email,
        redirectTo: 'kopilka://auth-callback',
      );

  static Future<void> resendVerificationEmail() =>
      _sb.auth.resend(type: OtpType.signup, email: userEmail!);

  static Future<void> updatePassword(String newPassword) =>
      _sb.auth.updateUser(UserAttributes(password: newPassword));
}
