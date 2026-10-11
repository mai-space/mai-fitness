import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/stats.dart';

/// Verlauf einer Übung als Linie, optional mit gestrichelter Prognose
/// (heute → in 8 Wochen).
class ProgressChart extends StatelessWidget {
  const ProgressChart({
    super.key,
    required this.points,
    this.prognosis,
    this.now,
    this.height = 180,
    this.format,
  });

  final List<Point> points;
  final Prognosis? prognosis;
  final DateTime? now;
  final double height;

  /// Beschriftung der Werte (Achse); Standard: ganze Zahl.
  final String Function(double value)? format;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final locale = Localizations.localeOf(context).languageCode;
    return Semantics(
      container: true,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _LinePainter(
            points: points,
            prognosis: prognosis,
            now: now ?? DateTime.now(),
            line: scheme.primary,
            forecast: scheme.tertiary,
            grid: scheme.outlineVariant,
            label: text,
            format: format ?? (v) => v.round().toString(),
            dateFormat: DateFormat.MMMd(locale),
          ),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.prognosis,
    required this.now,
    required this.line,
    required this.forecast,
    required this.grid,
    required this.label,
    required this.format,
    required this.dateFormat,
  });

  final List<Point> points;
  final Prognosis? prognosis;
  final DateTime now;
  final Color line;
  final Color forecast;
  final Color grid;
  final TextStyle label;
  final String Function(double) format;
  final DateFormat dateFormat;

  static const _left = 40.0;
  static const _bottom = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final p = prognosis;
    final end = p == null ? points.last.at : now.add(const Duration(days: 56));
    final start = points.first.at;
    var spanMs = end.difference(start).inMilliseconds.toDouble();
    if (spanMs <= 0) spanMs = const Duration(days: 1).inMilliseconds.toDouble();

    final values = [
      for (final x in points) x.value,
      if (p != null) ...[p.current, p.in4Weeks, p.in8Weeks],
    ];
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1) {
      hi += 1;
      lo = math.max(0, lo - 1);
    }
    final pad = (hi - lo) * 0.1;
    lo = math.max(0, lo - pad);
    hi += pad;

    final w = size.width - _left - 8;
    final h = size.height - _bottom - 8;
    double x(DateTime t) =>
        _left + w * (t.difference(start).inMilliseconds / spanMs);
    double y(double v) => 8 + h * (1 - (v - lo) / (hi - lo));

    // Gitter mit drei Linien und Werten.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final v = lo + (hi - lo) * i / 2;
      final yy = y(v);
      canvas.drawLine(Offset(_left, yy), Offset(size.width - 8, yy), gridPaint);
      _text(canvas, format(v), Offset(0, yy - 7), _left - 6, TextAlign.right);
    }
    _text(canvas, dateFormat.format(start), Offset(_left, size.height - 14), 80,
        TextAlign.left);
    _text(canvas, dateFormat.format(end), Offset(size.width - 88, size.height - 14),
        80, TextAlign.right);

    // Messwerte.
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(x(points[i].at), y(points[i].value));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = line;
    for (final pt in points) {
      canvas.drawCircle(Offset(x(pt.at), y(pt.value)), 3.5, dot);
    }

    // Prognose gestrichelt.
    if (p != null) {
      final from = Offset(x(now), y(p.current));
      final mid = Offset(x(now.add(const Duration(days: 28))), y(p.in4Weeks));
      final to = Offset(x(end), y(p.in8Weeks));
      final dash = Paint()
        ..color = forecast
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      _dashed(canvas, from, mid, dash);
      _dashed(canvas, mid, to, dash);
      canvas.drawCircle(to, 4, Paint()..color = forecast);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    var t = 0.0;
    while (t < d) {
      final s = a + dir * t;
      final e = a + dir * math.min(d, t + dash);
      canvas.drawLine(s, e, paint);
      t += dash + gap;
    }
  }

  void _text(Canvas canvas, String s, Offset at, double width, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: label),
      textAlign: align,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.prognosis != prognosis ||
      old.line != line ||
      old.now != now;
}

/// Trainings je Woche als Balken, Ziel als Linie.
class WeekBars extends StatelessWidget {
  const WeekBars({
    super.key,
    required this.counts,
    required this.goal,
    this.height = 96,
  });

  final List<int> counts;
  final int goal;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarPainter(
          counts: counts,
          goal: goal,
          reached: scheme.primary,
          open: scheme.primaryContainer,
          goalColor: scheme.outline,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.counts,
    required this.goal,
    required this.reached,
    required this.open,
    required this.goalColor,
  });

  final List<int> counts;
  final int goal;
  final Color reached;
  final Color open;
  final Color goalColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final top = math.max(goal, counts.reduce(math.max)).clamp(1, 99);
    final slot = size.width / counts.length;
    final barW = slot * 0.6;
    for (var i = 0; i < counts.length; i++) {
      final c = counts[i];
      final h = c == 0 ? 3.0 : size.height * c / top;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * slot + (slot - barW) / 2,
          size.height - h,
          barW,
          h,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = c >= goal ? reached : open);
    }
    final gy = size.height - size.height * goal / top;
    final paint = Paint()
      ..color = goalColor
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, gy), Offset(math.min(size.width, x + 4), gy), paint);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.counts != counts || old.goal != goal || old.reached != reached;
}
