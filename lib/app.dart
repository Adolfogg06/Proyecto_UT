import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_review_screen.dart';
import 'screens/consumer/consumer_shell.dart';
import 'screens/merchant/merchant_shell.dart';
import 'screens/merchant/merchant_application_status_screen.dart';
import 'ui_v2/redesign_flag.dart';
import 'ui_v2/theme/tanda_theme.dart';

class UltimaTandaApp extends StatelessWidget {
  const UltimaTandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Última Tanda',
        debugShowCheckedModeBanner: false,
        theme: kUseRedesign ? TandaTheme.light() : AppTheme.light(),
        darkTheme: kUseRedesign ? TandaTheme.dark() : null,
        themeMode: kUseRedesign ? ThemeMode.system : ThemeMode.light,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        final user = auth.appUser!;
        if (user.isAdmin) return const AdminReviewScreen();
        if (user.isMerchantPending || user.isMerchantRejected) {
          return MerchantApplicationStatusScreen(rejected: user.isMerchantRejected);
        }
        return auth.isComercio ? const MerchantShell() : const ConsumerShell();
    }
  }
}
