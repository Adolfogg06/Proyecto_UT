import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/merchant_provider.dart';

final _currency = NumberFormat.currency(locale: 'es_GT', symbol: 'Q');

/// Panel de microeconomía del comercio: costos de corto plazo derivados de
/// sus propias canastas/ventas, punto de equilibrio, y un simulador de
/// largo plazo. Solo visible para el comercio dueño de los datos.
class MicroeconomicsScreen extends StatefulWidget {
  const MicroeconomicsScreen({super.key});

  @override
  State<MicroeconomicsScreen> createState() => _MicroeconomicsScreenState();
}

class _MicroeconomicsScreenState extends State<MicroeconomicsScreen> {
  final _fixedCostCtrl = TextEditingController();
  bool _editingFixedCost = false;

  // Simulador de largo plazo (estado local, no se guarda).
  final _simCfCtrl = TextEditingController();
  final _simCvCtrl = TextEditingController();
  final _simPriceCtrl = TextEditingController();
  bool _simTouched = false;

  @override
  void dispose() {
    _fixedCostCtrl.dispose();
    _simCfCtrl.dispose();
    _simCvCtrl.dispose();
    _simPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MerchantProvider>();

    if (!_simTouched) {
      _simCfCtrl.text = provider.fixedCostMonthly.toStringAsFixed(0);
      _simCvCtrl.text = provider.avgUnitCost.toStringAsFixed(2);
      _simPriceCtrl.text = provider.avgSellPrice.toStringAsFixed(2);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de microeconomía')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _fixedCostCard(provider),
                const SizedBox(height: 16),
                _shortRunSummaryCard(provider),
                const SizedBox(height: 16),
                _breakEvenCard(provider),
                const SizedBox(height: 16),
                _averageCostCard(provider),
                const SizedBox(height: 24),
                _longRunSimulator(provider),
              ],
            ),
    );
  }

  // -------------------- Costo fijo mensual --------------------

  Widget _fixedCostCard(MerchantProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Costo fijo mensual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Alquiler, planilla base, servicios — lo que pagas aunque no vendas nada. '
              'Tú lo ingresas; el resto de los cálculos usa tus canastas y ventas reales.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (_editingFixedCost)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fixedCostCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Costo fijo mensual (Q)'),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppTheme.primaryGreen),
                    onPressed: () {
                      final value = double.tryParse(_fixedCostCtrl.text) ?? provider.fixedCostMonthly;
                      provider.setFixedCostMonthly(value);
                      setState(() => _editingFixedCost = false);
                    },
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_currency.format(provider.fixedCostMonthly),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {
                      _fixedCostCtrl.text =
                          provider.fixedCostMonthly > 0 ? provider.fixedCostMonthly.toStringAsFixed(0) : '';
                      setState(() => _editingFixedCost = true);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // -------------------- Resumen de corto plazo --------------------

  Widget _shortRunSummaryCard(MerchantProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Corto plazo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _row('Costo Variable unitario (CV)', _currency.format(provider.avgUnitCost),
                hint: 'Promedio del costo unitario que declaraste en tus canastas'),
            _row('Precio de venta promedio', _currency.format(provider.avgSellPrice),
                hint: provider.sellPriceIsEstimate
                    ? 'Estimado con tu precio de lista — aún no tienes ventas reales'
                    : 'Calculado con tus ventas reales'),
            _row('Margen de contribución', _currency.format(provider.contributionMargin),
                hint: 'Precio − CV: lo que aporta cada unidad a cubrir el costo fijo',
                color: provider.contributionMargin > 0 ? AppTheme.primaryGreen : Colors.red),
            _row('Costo Marginal (CMg)', _currency.format(provider.marginalCost),
                hint: 'Costo de producir una unidad más (= CV con este modelo de corto plazo)'),
          ],
        ),
      ),
    );
  }

  // -------------------- Punto de equilibrio --------------------

  Widget _breakEvenCard(MerchantProvider provider) {
    final be = provider.breakEvenUnits;
    final qMax = (be != null && be > 0) ? be * 2 : 50.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Punto de Equilibrio (PEM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (be == null)
              Text(
                provider.contributionMargin <= 0
                    ? 'Tu precio no cubre tu costo variable — no hay punto de equilibrio posible con estos números.'
                    : 'Ingresa tu costo fijo mensual para calcular el punto de equilibrio.',
                style: const TextStyle(color: Colors.red),
              )
            else ...[
              Text('${be.toStringAsFixed(1)} unidades/mes',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              Text('Ingreso = Costo en ese punto: ${_currency.format(provider.totalRevenueAt(be))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: qMax,
                    minY: 0,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: qMax / 4),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 54),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, provider.totalCostAt(0)),
                          FlSpot(qMax, provider.totalCostAt(qMax)),
                        ],
                        color: Colors.redAccent,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: [
                          FlSpot(0, provider.totalRevenueAt(0)),
                          FlSpot(qMax, provider.totalRevenueAt(qMax)),
                        ],
                        color: AppTheme.primaryGreen,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    extraLinesData: ExtraLinesData(verticalLines: [
                      VerticalLine(x: be, color: Colors.black38, dashArray: [6, 4], strokeWidth: 1.5),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _legendDot(Colors.redAccent, 'Costo Total'),
                  const SizedBox(width: 16),
                  _legendDot(AppTheme.primaryGreen, 'Ingreso Total'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------- Costo Medio (CMe) --------------------

  Widget _averageCostCard(MerchantProvider provider) {
    if (provider.fixedCostMonthly <= 0) return const SizedBox.shrink();
    final be = provider.breakEvenUnits;
    final qMax = (be != null && be > 0) ? be * 2 : 50.0;
    final points = <FlSpot>[];
    final steps = 30;
    for (var i = 1; i <= steps; i++) {
      final q = qMax * i / steps;
      final cme = provider.avgCostAt(q);
      if (cme != null) points.add(FlSpot(q, cme));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Costo Medio (CMe)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'CMe = CF/q + CV. Baja a medida que vendes más porque el costo fijo se reparte entre más unidades, '
              'y nunca baja de tu CV (${_currency.format(provider.avgUnitCost)}).',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: qMax,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: qMax / 4),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points,
                      color: AppTheme.accentOrange,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Simulador de largo plazo --------------------

  Widget _longRunSimulator(MerchantProvider provider) {
    final simCf = double.tryParse(_simCfCtrl.text) ?? 0;
    final simCv = double.tryParse(_simCvCtrl.text) ?? 0;
    final simPrice = double.tryParse(_simPriceCtrl.text) ?? 0;
    final simMargin = simPrice - simCv;
    final simBe = simMargin > 0 ? simCf / simMargin : null;

    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simulador de largo plazo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'En el largo plazo todos los costos son variables (puedes cambiar de local, '
              'renegociar precios, etc.). Ajusta estos valores hipotéticos — no se guardan, '
              'parten de tus cifras actuales.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _simCfCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'CF hipotético (Q)'),
                    onChanged: (_) => setState(() => _simTouched = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _simCvCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'CV hipotético (Q)'),
                    onChanged: (_) => setState(() => _simTouched = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _simPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio hipotético (Q)'),
              onChanged: (_) => setState(() => _simTouched = true),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: simBe == null
                  ? const Text('Con estos valores el margen no es positivo: no hay equilibrio posible.',
                      style: TextStyle(color: Colors.red))
                  : Text('Nuevo punto de equilibrio: ${simBe.toStringAsFixed(1)} unidades/mes',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- helpers --------------------

  Widget _row(String label, String value, {String? hint, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          if (hint != null)
            Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
