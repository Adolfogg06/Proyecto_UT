import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/basket.dart';
import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import '../../services/location_service.dart';

class CreateBasketScreen extends StatefulWidget {
  const CreateBasketScreen({super.key});

  @override
  State<CreateBasketScreen> createState() => _CreateBasketScreenState();
}

class _CreateBasketScreenState extends State<CreateBasketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _minPriceCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '20');
  final _includesCtrl = TextEditingController();

  static const _categories = ['Panadería', 'Restaurante', 'Supermercado', 'Pastelería', 'Vegano', 'Otro'];
  String _category = _categories.first;

  BasketType _type = BasketType.visible;
  TimeOfDay _pickupStart = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _pickupEnd = const TimeOfDay(hour: 21, minute: 0);
  bool _submitting = false;

  final List<_TierInput> _tiers = [
    _TierInput(time: const TimeOfDay(hour: 17, minute: 0), percent: 30),
    _TierInput(time: const TimeOfDay(hour: 18, minute: 30), percent: 50),
    _TierInput(time: const TimeOfDay(hour: 19, minute: 30), percent: 70),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _originalPriceCtrl.dispose();
    _minPriceCtrl.dispose();
    _unitCostCtrl.dispose();
    _includesCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _pickupStart : _pickupEnd;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => isStart ? _pickupStart = picked : _pickupEnd = picked);
    }
  }

  Future<void> _pickTierTime(int index) async {
    final picked = await showTimePicker(context: context, initialTime: _tiers[index].time);
    if (picked != null) setState(() => _tiers[index].time = picked);
  }

  void _addTier() {
    setState(() => _tiers.add(_TierInput(time: const TimeOfDay(hour: 20, minute: 0), percent: 80)));
  }

  void _removeTier(int index) => setState(() => _tiers.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final originalPrice = double.parse(_originalPriceCtrl.text);
    final minPrice = double.parse(_minPriceCtrl.text);
    if (minPrice > originalPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio mínimo no puede ser mayor al precio original')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.appUser!;
      final merchantProvider = context.read<MerchantProvider>();

      final now = DateTime.now();
      final location = user.businessLocation ?? LocationService.guatemalaCityDefault;

      final basket = Basket(
        id: '',
        merchantId: user.uid,
        merchantName: user.businessName.isNotEmpty ? user.businessName : user.displayName,
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        type: _type,
        originalPrice: originalPrice,
        minPrice: minPrice,
        unitCost: double.tryParse(_unitCostCtrl.text) ?? 0,
        quantityTotal: int.parse(_quantityCtrl.text),
        quantityAvailable: int.parse(_quantityCtrl.text),
        pickupWindowStart: _toDateTime(now, _pickupStart),
        pickupWindowEnd: _toDateTime(now, _pickupEnd),
        discountTiers: _tiers
            .map((t) => DiscountTier(triggerTime: _toDateTime(now, t.time), percentOff: t.percent))
            .toList(),
        location: location,
        address: user.businessAddress,
        merchantRating: user.businessRating,
        merchantReviewCount: user.businessReviewCount,
        category: _category,
        includes: _includesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

      await merchantProvider.createBasket(basket);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Canasta publicada con éxito')),
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

  DateTime _toDateTime(DateTime base, TimeOfDay time) =>
      DateTime(base.year, base.month, base.day, time.hour, time.minute);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar canasta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la canasta'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _includesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qué puede incluir (opcional)',
                    hintText: 'Pan de masa madre, Croissants, Galletas',
                    helperText: 'Sepáralo con comas — se muestra como lista al consumidor',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 12),
                const Text('Tipo de canasta', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SegmentedButton<BasketType>(
                  segments: const [
                    ButtonSegment(value: BasketType.visible, label: Text('Visible'), icon: Icon(Icons.visibility_outlined)),
                    ButtonSegment(value: BasketType.sorpresa, label: Text('Bolsa sorpresa'), icon: Icon(Icons.card_giftcard)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _originalPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio normal (Q)'),
                        validator: _numberValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio mínimo (Q)'),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _unitCostCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Costo unitario (Q, opcional)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cantidad disponible'),
                        validator: (v) => (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                            ? 'Cantidad inválida'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Ventana de recogida', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(true),
                        icon: const Icon(Icons.schedule),
                        label: Text('Desde ${_pickupStart.format(context)}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(false),
                        icon: const Icon(Icons.schedule),
                        label: Text('Hasta ${_pickupEnd.format(context)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Franjas de descuento', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(onPressed: _addTier, icon: const Icon(Icons.add), label: const Text('Agregar')),
                  ],
                ),
                Text(
                  'El precio baja automáticamente en cada horario, sin bajar del precio mínimo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ..._tiers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tier = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickTierTime(i),
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(tier.time.format(context)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Baja a'),
                          Expanded(
                            child: Slider(
                              value: tier.percent,
                              min: 10,
                              max: 90,
                              divisions: 16,
                              label: '-${tier.percent.round()}%',
                              activeColor: AppTheme.accentOrange,
                              onChanged: (v) => setState(() => tier.percent = v),
                            ),
                          ),
                          Text('-${tier.percent.round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: _tiers.length > 1 ? () => _removeTier(i) : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publicar canasta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requerido';
    if (double.tryParse(v) == null) return 'Número inválido';
    return null;
  }
}

class _TierInput {
  TimeOfDay time;
  double percent;
  _TierInput({required this.time, required this.percent});
}
