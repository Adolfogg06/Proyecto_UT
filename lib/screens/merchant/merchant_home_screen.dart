import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/basket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../widgets/countdown_price_widget.dart';
import '../../widgets/stat_tile.dart';
import '../shared/solidarity_donation_screen.dart';
import 'create_basket_screen.dart';

class MerchantHomeScreen extends StatelessWidget {
  const MerchantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MerchantProvider>();
    final currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del comercio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const CreateBasketScreen(),
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          icon: Icons.payments_outlined,
                          value: currency.format(provider.totalRevenue),
                          label: 'Ingreso recuperado',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          icon: Icons.shopping_basket_outlined,
                          value: '${provider.totalUnitsSold}',
                          label: 'Unidades vendidas',
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatTile(
                          icon: Icons.storefront_outlined,
                          value: '${provider.activeBaskets.length}',
                          label: 'Canastas activas',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Comisión de plataforma (${AppConstants.platformFeePercent.toStringAsFixed(0)}%) ya descontada: '
                      '${currency.format(provider.totalPlatformFees)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Ofertas activas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (provider.activeBaskets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No tienes canastas activas. Publica la primera con el botón "+".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  else
                    ...provider.activeBaskets.map((b) => _MerchantBasketCard(basket: b)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _MerchantBasketCard extends StatelessWidget {
  final Basket basket;
  const _MerchantBasketCard({required this.basket});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(basket.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text('${basket.quantityAvailable}/${basket.quantityTotal} disp.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 6),
            CountdownPriceWidget(basket: basket),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SolidarityDonationScreen(basket: basket)),
                ),
                icon: const Icon(Icons.volunteer_activism, size: 18, color: AppTheme.accentOrange),
                label: const Text('Rescate solidario', style: TextStyle(color: AppTheme.accentOrange)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.accentOrange)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
