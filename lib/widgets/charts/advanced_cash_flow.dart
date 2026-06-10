import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../utils/format.dart';

class CashFlowPoint {
  final String key;
  final String label;
  final num inc;
  final num exp;
  const CashFlowPoint(this.key, this.label, this.inc, this.exp);
}

enum CashFlowMode { combo, bars, area, lines }

class AdvancedCashFlow extends StatefulWidget {
  final List<CashFlowPoint> data;
  final bool hideIncome;
  final bool hideExpense;

  const AdvancedCashFlow({
    super.key,
    required this.data,
    this.hideIncome = false,
    this.hideExpense = false,
  });

  @override
  State<AdvancedCashFlow> createState() => _AdvancedCashFlowState();
}

class _AdvancedCashFlowState extends State<AdvancedCashFlow> {
  CashFlowMode mode = CashFlowMode.combo;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('Belum ada data di rentang ini',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: RetroColor.gray400, fontSize: 12)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: [
            _ModeBtn(label: 'Combo', icon: Icons.bar_chart, active: mode == CashFlowMode.combo, onTap: () => setState(() => mode = CashFlowMode.combo)),
            _ModeBtn(label: 'Bar', icon: Icons.bar_chart, active: mode == CashFlowMode.bars, onTap: () => setState(() => mode = CashFlowMode.bars)),
            _ModeBtn(label: 'Area', icon: Icons.area_chart, active: mode == CashFlowMode.area, onTap: () => setState(() => mode = CashFlowMode.area)),
            _ModeBtn(label: 'Line', icon: Icons.show_chart, active: mode == CashFlowMode.lines, onTap: () => setState(() => mode = CashFlowMode.lines)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (widget.data.length * 42).clamp(540, 4000).toDouble(),
              child: CustomPaint(
                painter: _CashFlowPainter(widget.data, mode),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _legend(),
      ],
    );
  }

  Widget _legend() {
    Widget swatch(Color c) => Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: c, border: Border.all(color: RetroColor.ink, width: 1)));
    Widget tile(Widget icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))]);
    return Wrap(spacing: 12, runSpacing: 4, children: [
      tile(swatch(RetroColor.green400), 'Pemasukan'),
      tile(swatch(RetroColor.red400), 'Pengeluaran'),
      tile(Container(width: 16, height: 3, color: RetroColor.blue700), 'Akumulasi Net'),
    ]);
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = active ? RetroColor.cream : RetroColor.ink;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? RetroColor.ink : Colors.white,
          border: Border.all(
              color: active ? RetroColor.ink : RetroColor.gray300, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ]),
      ),
    );
  }
}

class _CashFlowPainter extends CustomPainter {
  final List<CashFlowPoint> data;
  final CashFlowMode mode;
  _CashFlowPainter(this.data, this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    const padX = 28.0;
    const padTop = 16.0;
    const padBottom = 30.0;
    final w = size.width;
    final h = size.height;
    if (data.isEmpty) return;

    final cums = <double>[];
    double cum = 0;
    final incs = data.map((d) => d.inc.toDouble()).toList();
    final exps = data.map((d) => d.exp.toDouble()).toList();
    final win = (data.length ~/ 4).clamp(2, 7);
    final avgIncs = <double>[];
    final avgExps = <double>[];
    for (var i = 0; i < data.length; i++) {
      cum += incs[i] - exps[i];
      cums.add(cum);
      final start = (i - win + 1).clamp(0, i);
      double si = 0, se = 0;
      var n = 0;
      for (var j = start; j <= i; j++) { si += incs[j]; se += exps[j]; n++; }
      avgIncs.add(si / n);
      avgExps.add(se / n);
    }
    final maxIO = [...incs, ...exps].fold<double>(1, (m, v) => v > m ? v : m);
    final cumMax = cums.fold<double>(0, (m, v) => v > m ? v : m).clamp(1, double.infinity);
    final cumMin = cums.fold<double>(0, (m, v) => v < m ? v : m);
    final cumRange = (cumMax - cumMin).clamp(1, double.infinity);

    double xFor(int i) =>
        (i / (data.length == 1 ? 1 : data.length - 1)) * (w - padX * 2) + padX;
    double yIO(double v) => h - padBottom - (v / maxIO) * (h - padTop - padBottom);
    double yCum(double v) =>
        h - padBottom - ((v - cumMin) / cumRange) * (h - padTop - padBottom);

    final gridPaint = Paint()..color = RetroColor.gray200..strokeWidth = 1;
    for (final p in [0.25, 0.5, 0.75]) {
      final y = padTop + (h - padTop - padBottom) * p;
      canvas.drawLine(Offset(padX, y), Offset(w - padX, y), gridPaint);
    }

    canvas.drawLine(Offset(padX, yIO(0)), Offset(w - padX, yIO(0)),
        Paint()..color = RetroColor.ink..strokeWidth = 1);

    if (mode == CashFlowMode.area) {
      final incPath = Path()..moveTo(xFor(0), yIO(0));
      final expPath = Path()..moveTo(xFor(0), yIO(0));
      for (var i = 0; i < data.length; i++) {
        incPath.lineTo(xFor(i), yIO(incs[i]));
        expPath.lineTo(xFor(i), yIO(exps[i]));
      }
      incPath..lineTo(xFor(data.length - 1), yIO(0))..close();
      expPath..lineTo(xFor(data.length - 1), yIO(0))..close();
      canvas.drawPath(incPath, Paint()..color = const Color(0x888AA678));
      canvas.drawPath(expPath, Paint()..color = const Color(0x88BF6B57));
    }

    if (mode == CashFlowMode.bars || mode == CashFlowMode.combo) {
      final barW = ((w - padX * 2) / data.length / 2.4).clamp(2.0, 14.0);
      final incPaint = Paint()..color = RetroColor.green400;
      final expPaint = Paint()..color = RetroColor.red400;
      final stroke = Paint()..color = RetroColor.ink..style = PaintingStyle.stroke..strokeWidth = 1;
      for (var i = 0; i < data.length; i++) {
        final x = xFor(i);
        final incRect = Rect.fromLTRB(x - barW - 1, yIO(incs[i]), x - 1, yIO(0));
        final expRect = Rect.fromLTRB(x + 1, yIO(exps[i]), x + 1 + barW, yIO(0));
        canvas.drawRect(incRect, incPaint);
        canvas.drawRect(incRect, stroke);
        canvas.drawRect(expRect, expPaint);
        canvas.drawRect(expRect, stroke);
      }
    }

    if (mode == CashFlowMode.lines || mode == CashFlowMode.combo) {
      void drawSeries(List<double> ys, Color color) {
        final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
        for (var i = 1; i < data.length; i++) {
          canvas.drawLine(
            Offset(xFor(i - 1), yIO(ys[i - 1])),
            Offset(xFor(i), yIO(ys[i])),
            p,
          );
        }
      }
      drawSeries(avgIncs, RetroColor.green600);
      drawSeries(avgExps, RetroColor.red700);
    }

    if (mode == CashFlowMode.combo) {
      final cumPaint = Paint()
        ..color = RetroColor.blue700
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(xFor(0), yCum(cums[0]));
      for (var i = 1; i < cums.length; i++) {
        path.lineTo(xFor(i), yCum(cums[i]));
      }
      canvas.drawPath(path, cumPaint);
      final dot = Paint()..color = RetroColor.blue700;
      for (var i = 0; i < cums.length; i++) {
        canvas.drawCircle(Offset(xFor(i), yCum(cums[i])), 3, dot);
      }
    }

    const textStyle = TextStyle(
        color: RetroColor.ink, fontWeight: FontWeight.w700, fontSize: 9, fontFamily: 'monospace');
    for (var i = 0; i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: data[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xFor(i) - tp.width / 2, h - padBottom + 6));
    }

    final maxTp = TextPainter(
      text: TextSpan(text: formatCompact(maxIO), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    maxTp.paint(canvas, const Offset(4, padTop));
    final cumMaxTp = TextPainter(
      text: TextSpan(
          text: formatCompact(cumMax), style: textStyle.copyWith(color: RetroColor.blue700)),
      textDirection: TextDirection.ltr,
    )..layout();
    cumMaxTp.paint(canvas, Offset(w - 4 - cumMaxTp.width, padTop));
  }

  @override
  bool shouldRepaint(covariant _CashFlowPainter old) =>
      old.data != data || old.mode != mode;
}
