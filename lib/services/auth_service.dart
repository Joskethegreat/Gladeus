import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Thin wrapper around Supabase Auth. The session is saved on the device by
/// supabase_flutter and restored on the next launch, so there is nothing to
/// persist here. Only use it when [SupabaseService.isConnected] is true.
class AuthService {
  static GoTrueClient get _auth => SupabaseService.client.auth;

  static User? get currentUser => _auth.currentUser;
  static Session? get currentSession => _auth.currentSession;

  /// Emits on sign in, sign out, token refresh and so on.
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Returns true when the user is signed in straight away. False means the
  /// project requires email confirmation first.
  static Future<bool> signUp(String email, String password) async {
    final res = await _auth.signUp(email: email, password: password);
    return res.session != null;
  }

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() => _auth.signOut();
}
