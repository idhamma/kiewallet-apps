import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/constants.dart';

class PieSlice {
  final String label;
  final num value;
  final Color color;
  const PieSlice(this.label, this.value, this.color);
}

class PieDistribution extends StatelessWidget {
  final List<PieSlice> slices;
  final double size;
  const PieDistribution({super.key, required this.slices, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<num>(0, (s, x) => s + x.value);
    if (total <= 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: RetroColor.gray300, width: 1),
        ),
        child: const Center(
          child: Text('NOL\nSALDO',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: RetroColor.gray400)),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: RetroColor.ink, width: 1),
      ),
      child: CustomPaint(painter: _PiePainter(slices, total.toDouble())),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<PieSlice> slices;
  final double total;
  _PiePainter(this.slices, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    var start = -pi / 2;
    for (final s in slices) {
      final sweep = (s.value / total) * 2 * pi;
      final paint = Paint()..color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, sweep, true, paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) => old.slices != slices;
}
