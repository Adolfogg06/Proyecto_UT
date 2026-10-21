import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/role_selector.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _businessAddressCtrl = TextEditingController();

  UserRole? _role = UserRole.consumidor;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _role == null) return;
    final auth = context.read<AuthProvider>();

    GeoPoint? businessLocation;
    if (_role == UserRole.comercio) {
      try {
        businessLocation = await LocationService().getCurrentLocation();
      } catch (_) {
        businessLocation = LocationService.guatemalaCityDefault;
      }
    }

    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text.trim(),
      role: _role!,
      businessName: _businessNameCtrl.text.trim(),
      businessAddress: _businessAddressCtrl.text.trim(),
      businessLocation: businessLocation,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isComercio = _role == UserRole.comercio;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('¿Cómo quieres usar Última Tanda?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                RoleSelector(selected: _role, onChanged: (r) => setState(() => _role = r)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: isComercio ? 'Nombre de contacto' : 'Nombre completo'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                if (isComercio) ...[
                  TextFormField(
                    controller: _businessNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del comercio'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessAddressCtrl,
                    decoration: const InputDecoration(labelText: 'Dirección del comercio'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
