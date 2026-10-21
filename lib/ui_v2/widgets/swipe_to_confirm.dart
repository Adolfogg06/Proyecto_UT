import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/tanda_colors.dart';
import '../theme/tanda_theme.dart';

/// Deslizador antifraude de la pantalla de Recogida — ver README.
///
/// [onConfirm] se llama solo al soltar pasado el 90% del recorrido; debe
/// devolver `true` si el backend aceptó la confirmación. En `true`, el
/// padre normalmente reemplaza este widget por el banner de éxito en
/// cuanto el stream de la reserva refleje `picked_up` — este widget no
/// gestiona ese estado "recogido" por sí mismo, solo el gesto.
class SwipeToConfirm extends StatefulWidget {
  final Future<bool> Function() onConfirm;
  const SwipeToConfirm({super.key, required this.onConfirm});

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  static const _knob = 56.0;
  static const _trackHeight = 64.0;
  static const _pad = 4.0;

  double _x = 0;
  bool _dragging = false;
  bool _busy = false;

  double _maxX(double trackWidth) => (trackWidth - _knob - _pad * 2).clamp(0, double.infinity);

  void _onPanUpdate(DragUpdateDetails d, double maxX) {
    if (_busy) return;
    setState(() {
      _dragging = true;
      _x = (_x + d.delta.dx).clamp(0, maxX);
    });
  }

  Future<void> _onPanEnd(DragEndDetails d, double maxX) async {
    if (_busy) return;
    setState(() => _dragging = false);
    if (maxX > 0 && _x / maxX >= 0.9) {
      setState(() {
        _busy = true;
        _x = maxX;
      });
      HapticFeedback.mediumImpact();
      final ok = await widget.onConfirm();
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _x = 0;
        });
      }
      // En éxito dejamos el knob al final: el padre reemplaza este widget
      // por el banner de éxito en cuanto el stream confirme `picked_up`.
    } else {
      setState(() => _x = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.tanda;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shieldCheck, size: 14, color: c.muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Desliza solo frente al personal. No se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxX = _maxX(constraints.maxWidth);
            final double x = _x.clamp(0.0, maxX);
            final progress = maxX > 0 ? x / maxX : 0.0;
            return SizedBox(
              height: _trackHeight,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(color: c.greenSoft, borderRadius: BorderRadius.circular(TandaRadii.slider)),
                  ),
                  Container(
                    width: x + _knob + _pad,
                    decoration: BoxDecoration(color: c.green, borderRadius: BorderRadius.circular(TandaRadii.slider)),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Opacity(
                          opacity: (1 - progress * 1.6).clamp(0, 1),
                          child: Text(
                            'Desliza para confirmar recogida',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.green),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _dragging || _busy ? Duration.zero : const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    top: _pad,
                    left: x,
                    child: GestureDetector(
                      onPanUpdate: (d) => _onPanUpdate(d, maxX),
                      onPanEnd: (d) => _onPanEnd(d, maxX),
                      child: Container(
                        width: _knob,
                        height: _knob,
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: _busy
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: c.green),
                              )
                            : Icon(LucideIcons.chevronsRight, color: c.green, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
