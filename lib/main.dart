import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'services/api_service.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/widgets/app_shell.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock status bar to light icons for our dark theme
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // Initialize API service singleton
  ApiService.instance.init();

  runApp(const ProviderScope(child: FusionStrikeApp()));
}

/// Root application widget.
///
/// Routes between Login and AppShell based on auth state.
class FusionStrikeApp extends ConsumerWidget {
  const FusionStrikeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Fusion Strike AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _buildHome(authState),
    );
  }

  Widget _buildHome(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.unknown:
        // Still checking stored token — show splash
        return const _SplashScreen();
      case AuthStatus.authenticated:
        return const AppShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

/// Minimal splash screen shown while checking auth state.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
