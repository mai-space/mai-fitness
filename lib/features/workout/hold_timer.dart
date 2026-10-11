import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';

/// Halte-Timer (Plank, Wandsitzen): zählt bis zum Ziel herunter und danach
/// weiter hoch — wer länger hält, bekommt die volle Zeit eingetragen.
/// Liefert die gehaltenen Sekunden oder `null` bei Abbruch.
Future<int?> showHoldTimer(BuildContext context, int targetSeconds) =>
    showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _HoldTimer(target: targetSeconds),
    );

class _HoldTimer extends StatefulWidget {
  const _HoldTimer({required this.target});

  final int target;

  @override
  State<_HoldTimer> createState() => _HoldTimerState();
}

class _HoldTimerState extends State<_HoldTimer> {
  /// Countdown vor dem Start (in Position gehen).
  int _prepare = 5;
  final _watch = Stopwatch();
  Timer? _timer;
  bool _reached = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    if (!_watch.isRunning && _prepare > 0) {
      // Vorbereitung in ganzen Sekunden.
      if (_timer!.tick % 4 == 0) {
        _prepare--;
        if (_prepare == 0) {
          HapticFeedback.mediumImpact();
          _watch.start();
        }
      }
    }
    if (!_reached && _watch.elapsed.inSeconds >= widget.target) {
      _reached = true;
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final held = _watch.elapsed.inSeconds;
    final preparing = !_watch.isRunning && _prepare > 0;
    final remaining = widget.target - held;
    final big = preparing
        ? '$_prepare'
        : (remaining > 0 ? '$remaining' : '+${-remaining}');
    return AlertDialog(
      title: Text(preparing ? l10n.holdGetReady : l10n.holdHold),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: preparing
                        ? 0
                        : (held / widget.target).clamp(0, 1).toDouble(),
                    strokeWidth: 10,
                  ),
                ),
                Text(
                  big,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _reached ? l10n.holdReached : l10n.holdTarget(widget.target),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: preparing
              ? null
              : () => Navigator.pop(context, _watch.elapsed.inSeconds),
          child: Text(l10n.holdStop),
        ),
      ],
    );
  }
}
