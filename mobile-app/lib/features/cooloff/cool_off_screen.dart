import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Cool-off countdown screen — matches web app's cool-off-countdown.tsx
class CoolOffScreen extends StatefulWidget {
  final double price;
  final String label;
  final String category;

  const CoolOffScreen({
    super.key,
    required this.price,
    required this.label,
    required this.category,
  });

  @override
  State<CoolOffScreen> createState() => _CoolOffScreenState();
}

class _CoolOffScreenState extends State<CoolOffScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = 10;
  late AnimationController _controller;
  int _secondsLeft = _duration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _duration),
    );
    _controller.forward();
    _controller.addListener(_tick);
  }

  void _tick() {
    final newSeconds = _duration - (_controller.value * _duration).floor();
    if (newSeconds != _secondsLeft) {
      setState(() => _secondsLeft = newSeconds);
    }
    if (_controller.isCompleted) {
      context.go(
        '/results',
        extra: {
          'price': widget.price,
          'label': widget.label,
          'category': widget.category,
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = context.colors;
    final progress = _controller.value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text('Pause.', style: theme.textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Give yourself a moment before\nyou see the numbers.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: ext.mutedForeground,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Circular timer
              SizedBox(
                width: 144,
                height: 144,
                child: CustomPaint(
                  painter: _TimerPainter(
                    progress: progress,
                    bgColor: ext.border,
                    fgColor: theme.colorScheme.primary,
                  ),
                  child: Center(
                    child: Text(
                      '$_secondsLeft',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Impulse spending relies on speed. This tiny delay alone reduces regretful purchases.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ext.mutedForeground.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  _TimerPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) => old.progress != progress;
}
