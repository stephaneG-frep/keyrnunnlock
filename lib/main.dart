import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'screens/create_master_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/unlock_screen.dart';
import 'services/auth_service.dart';
import 'services/crypto_service.dart';
import 'services/secure_storage_service.dart';
import 'services/vault_service.dart';
import 'utils/app_theme.dart';
import 'widgets/activity_listener.dart';
import 'widgets/lifecycle_lock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KeyrnunnlockApp());
}

class KeyrnunnlockApp extends StatelessWidget {
  const KeyrnunnlockApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = const SecureStorageService();
    final crypto = CryptoService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: AuthService(storage: storage, crypto: crypto),
          )..init(),
        ),
        ChangeNotifierProvider<VaultProvider>(
          create: (_) => VaultProvider(
            vaultService: VaultService(storage: storage, crypto: crypto),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Keyrnunnlock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme(),
        home: Builder(
          builder: (context) {
            return LifecycleLock(
              child: ActivityListener(
                onActivity: context.read<AuthProvider>().registerUserActivity,
                child: const _RootGate(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vault = context.read<VaultProvider>();

    if (auth.stage != AuthStage.unlocked && vault.entries.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<VaultProvider>().clearForLock();
        }
      });
    }

    switch (auth.stage) {
      case AuthStage.loading:
        return const SplashScreen();
      case AuthStage.setup:
        return const CreateMasterPasswordScreen();
      case AuthStage.locked:
        return const UnlockScreen();
      case AuthStage.unlocked:
        final key = auth.sessionKey;
        if (key == null) {
          return const UnlockScreen();
        }
        return HomeScreen(sessionKey: key);
    }
  }
}
