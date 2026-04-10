import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  const AuthRepository(this._client);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

  /// Abre el navegador para autenticación OAuth con Google.
  /// Requiere configurar el redirect en Supabase Dashboard y AndroidManifest/Info.plist.
  Future<bool> signInWithGoogle() => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.finpa://login-callback/',
      );

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);

  User? getCurrentUser() => _client.auth.currentUser;
}

