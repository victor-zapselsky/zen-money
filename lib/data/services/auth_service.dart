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
        emailRedirectTo: 'kopilka://auth-callback',
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

  /// Converts Supabase auth/db errors into a user-facing Russian message.
  static String describeError(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Неверный email или пароль';
      }
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user already registered')) {
        return 'Пользователь с таким email уже зарегистрирован';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email не подтверждён. Проверьте почту и перейдите по ссылке из письма.';
      }
      if (msg.contains('password should be at least') ||
          msg.contains('password is too short')) {
        return 'Пароль должен быть не менее 6 символов';
      }
      if (msg.contains('unable to validate email address') ||
          msg.contains('invalid email')) {
        return 'Некорректный адрес электронной почты';
      }
      if (msg.contains('rate limit')) {
        return 'Слишком много попыток. Попробуйте позже.';
      }
      if (msg.contains('same password') || msg.contains('same_password')) {
        return 'Новый пароль должен отличаться от старого';
      }
      if (msg.contains('expired') || msg.contains('invalid token') ||
          msg.contains('otp')) {
        return 'Ссылка или код устарели. Запросите письмо ещё раз.';
      }
      if (msg.contains('user not found')) {
        return 'Пользователь не найден';
      }
      if (msg.contains('network') || msg.contains('socket') ||
          msg.contains('connection')) {
        return 'Нет соединения с сервером. Проверьте интернет.';
      }
      return 'Ошибка авторизации. Попробуйте ещё раз.';
    }
    if (error is PostgrestException) {
      return 'Не удалось синхронизировать данные с облаком. Попробуйте позже.';
    }
    return 'Произошла ошибка. Проверьте соединение.';
  }
}
