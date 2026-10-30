import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final _firestoreService = FirestoreService();
  late final Stream<List<AppUser>> _applications;
  String? _reviewingId;

  @override
  void initState() {
    super.initState();
    _applications = _firestoreService.pendingMerchantApplicationsStream();
  }

  Future<void> _review(AppUser merchant, {required bool approve}) async {
    setState(() => _reviewingId = merchant.uid);
    try {
      await _firestoreService.reviewMerchantApplication(
        merchantId: merchant.uid,
        adminId: context.read<AuthProvider>().appUser!.uid,
        approve: approve,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve
              ? 'Comercio aprobado. Ya puede publicar ofertas.'
              : 'Solicitud rechazada.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la solicitud.')),
      );
    } finally {
      if (mounted) setState(() => _reviewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de comercios'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _applications,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudieron cargar las solicitudes.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final applications = snapshot.data!;
          if (applications.isEmpty) {
            return const Center(child: Text('No hay solicitudes pendientes.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final merchant = applications[index];
              final isReviewing = _reviewingId == merchant.uid;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(merchant.businessName,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Contacto: ${merchant.displayName}'),
                      Text('Correo: ${merchant.email}'),
                      if (merchant.businessAddress.isNotEmpty)
                        Text('Dirección: ${merchant.businessAddress}'),
                      const SizedBox(height: 16),
                      if (isReviewing)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _review(merchant, approve: false),
                                child: const Text('Rechazar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _review(merchant, approve: true),
                                child: const Text('Aprobar'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
