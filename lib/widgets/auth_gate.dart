import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../root_shell.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

/// Shows the app when someone is signed in, the login screen otherwise.
/// The saved session is restored by Supabase before the first frame, so a
/// returning user goes straight to the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // No Supabase keys: keep working locally, as before.
    if (!SupabaseService.isConnected) return const RootShell();

    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      initialData: AuthState(AuthChangeEvent.initialSession, AuthService.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) return const LoginScreen();
        // Keyed by user so switching accounts rebuilds the shell and reloads data.
        return RootShell(key: ValueKey(session.user.id));
      },
    );
  }
}
