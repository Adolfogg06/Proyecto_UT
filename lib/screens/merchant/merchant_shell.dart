import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import 'merchant_home_screen.dart';

class MerchantShell extends StatelessWidget {
  const MerchantShell({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().appUser!.uid;
    return ChangeNotifierProvider(
      create: (_) => MerchantProvider(uid),
      child: const MerchantHomeScreen(),
    );
  }
}
