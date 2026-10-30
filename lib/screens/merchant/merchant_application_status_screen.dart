import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MerchantApplicationStatusScreen extends StatelessWidget {
  final bool rejected;

  const MerchantApplicationStatusScreen({super.key, required this.rejected});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser!;
    final color = rejected ? Colors.redAccent : Colors.orange;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitud de comercio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(rejected ? Icons.info_outline : Icons.hourglass_top,
                  size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                rejected ? 'Solicitud no aprobada' : 'Solicitud en revisión',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                rejected
                    ? 'La solicitud de ${user.businessName} no fue aprobada. Contacta al equipo de Última Tanda para recibir más información.'
                    : 'Recibimos la solicitud de ${user.businessName}. Podrás publicar ofertas cuando el equipo la apruebe.',
                textAlign: TextAlign.center,
              ),
              if (!rejected) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().refreshUser(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar estado'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
