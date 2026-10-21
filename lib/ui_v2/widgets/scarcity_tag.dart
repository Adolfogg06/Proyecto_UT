import 'package:flutter/material.dart';
import '../theme/tanda_colors.dart';

/// Etiqueta de disponibilidad de una canasta — ver README, sección
/// "Tag de escasez". [quantityAvailable] decide el estado: 1-3 unidades
/// (urgente, con punto pulsante), >3 (texto neutro), 0 (agotado).
class ScarcityTag extends StatefulWidget {
  final int quantityAvailable;
  final bool compact;
  const ScarcityTag({super.key, required this.quantityAvailable, this.compact = false});

  @override
  State<ScarcityTag> createState() => _ScarcityTagState();
}

class _ScarcityTagState extends State<ScarcityTag> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _label {
    final n = widget.quantityAvailable;
    if (n <= 0) return 'Agotado · vuelve mañana';
    if (n == 1) return '¡Solo queda 1!';
    if (n <= 3) return '¡Solo quedan $n!';
    return '$n disponibles';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    final n = widget.quantityAvailable;

    if (n <= 0) {
      return _pill(
        background: c.ink,
        child: Text(_label, style: TextStyle(color: c.bg, fontSize: 13, fontWeight: FontWeight.w600)),
      );
    }
    if (n > 3) {
      return _pill(
        background: widget.compact ? Colors.transparent : c.surface,
        child: Text(
          _label,
          style: TextStyle(
            color: widget.compact ? c.muted : c.ink,
            fontSize: widget.compact ? 12 : 13,
            fontWeight: widget.compact ? FontWeight.w600 : FontWeight.w600,
          ),
        ),
      );
    }
    // Urgente: punto pulsante + fondo rojo (o texto rojo en variante compacta).
    final dot = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Opacity(
          opacity: 1 - t * 0.65,
          child: Transform.scale(
            scale: 1 - t * 0.25,
            child: Container(
              width: widget.compact ? 6 : 7,
              height: widget.compact ? 6 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.compact ? c.red : Colors.white,
              ),
            ),
          ),
        );
      },
    );
    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 5),
          Text(_label, style: TextStyle(color: c.red, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      );
    }
    return _pill(
      background: c.red,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(_label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _pill({required Color background, required Widget child}) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.center,
      child: child,
    );
  }
}
