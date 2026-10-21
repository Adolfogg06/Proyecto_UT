import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/basket.dart';
import '../../models/donation.dart';
import '../../services/firestore_service.dart';

/// Permite al comercio donar una canasta completa (en vez de venderla)
/// a un banco de alimentos o comedor solidario cercano.
class SolidarityDonationScreen extends StatefulWidget {
  final Basket basket;
  const SolidarityDonationScreen({super.key, required this.basket});

  @override
  State<SolidarityDonationScreen> createState() => _SolidarityDonationScreenState();
}

class _SolidarityDonationScreenState extends State<SolidarityDonationScreen> {
  final _firestoreService = FirestoreService();
  Ngo? _selectedNgo;
  bool _submitting = false;

  Future<void> _confirmDonation(Ngo ngo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar donación'),
        content: Text(
          'Vas a donar "${widget.basket.title}" (${widget.basket.quantityAvailable} unidades) a ${ngo.name}. '
          'Esta canasta dejará de estar disponible para venta.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Donar')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _selectedNgo = ngo;
      _submitting = true;
    });
    try {
      await _firestoreService.donateBasket(basket: widget.basket, ngo: ngo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Gracias! "${widget.basket.title}" fue donada a ${ngo.name}.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescate solidario')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppTheme.accentOrange.withValues(alpha: 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volunteer_activism, color: AppTheme.accentOrange),
                      SizedBox(width: 8),
                      Text('Dona en lugar de descartar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Si "${widget.basket.title}" no se vendió a tiempo, dónala a un banco de alimentos '
                    'o comedor solidario cercano en lugar de que se desperdicie.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Ngo>>(
                stream: _firestoreService.ngosStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final ngos = snapshot.data!;
                  if (ngos.isEmpty) {
                    return const Center(child: Text('No hay bancos de alimentos registrados aún'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: ngos.length,
                    itemBuilder: (context, i) {
                      final ngo = ngos[i];
                      final isSubmittingThis = _submitting && _selectedNgo?.id == ngo.id;
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryGreen,
                            child: Icon(Icons.church_outlined, color: Colors.white, size: 20),
                          ),
                          title: Text(ngo.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(ngo.address),
                          trailing: isSubmittingThis
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : FilledButton(
                                  onPressed: _submitting ? null : () => _confirmDonation(ngo),
                                  child: const Text('Donar'),
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
