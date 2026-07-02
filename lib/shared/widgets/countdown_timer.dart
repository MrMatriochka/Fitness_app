import 'dart:async';

import 'package:flutter/material.dart';

/// Timer à rebours réutilisable pour les timers de repos et d'exercice (§5).
///
/// Affiche mm:ss, permet pause / reprise / réinitialisation et notifie la fin
/// via [onFinished]. Volontairement autonome (pas de dépendance à un provider)
/// pour rester simple et robuste pendant la séance (priorité UX §19.4).
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.seconds,
    this.autoStart = true,
    this.onFinished,
  });

  final int seconds;
  final bool autoStart;
  final VoidCallback? onFinished;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    if (widget.autoStart) _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running || _remaining <= 0) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _remaining = 0;
          _stop();
          widget.onFinished?.call();
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() => _running = false);
  }

  void _reset() {
    _stop();
    setState(() => _remaining = widget.seconds);
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.seconds == 0 ? 0.0 : _remaining / widget.seconds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                ),
              ),
              Text(
                _label,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: _running ? _stop : _start,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            IconButton.outlined(
              onPressed: _reset,
              icon: const Icon(Icons.replay),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ouvre le timer dans une feuille modale. [title] décrit le contexte
/// (« Repos », « Gainage »…).
Future<void> showCountdownSheet(
  BuildContext context, {
  required String title,
  required int seconds,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          CountdownTimer(
            seconds: seconds,
            onFinished: () {
              // Léger retour visuel : la barre atteint zéro. On pourrait ajouter
              // un son / une vibration en V1.5.
            },
          ),
        ],
      ),
    ),
  );
}
