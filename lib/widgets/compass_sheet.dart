import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/device_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';
import 'slide_up_sheet.dart';

/// Slides up a full compass from the Device tab's Compass card. The dial
/// turns with the phone's live heading while the sheet is open. It opens
/// at compass height; once there are directions to list, drag it up for
/// Recent.
Future<void> showCompassSheet(BuildContext context, DeviceService device) {
  return showSlideUpSheet(
    context,
    listenable: device,
    crossAxisAlignment: CrossAxisAlignment.center,
    peekHeight: (context) => _dialSize(context) + _peekChrome,
    canExpand: () => device.directionHistory.isNotEmpty,
    children: (context) => [
      _CompassContent(
        heading: device.heading,
        direction: device.direction,
        history: device.directionHistory,
      ),
    ],
  );
}

/// Fits portrait and landscape: never taller than about half the screen.
double _dialSize(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return math.min(size.width - 64, size.height * 0.5).clamp(160.0, 340.0);
}

/// Height of everything in the compass part except the dial: title,
/// marker and reading, with their gaps.
const _peekChrome = 24 + 16 + 36 + 20 + 40.0;

class _CompassContent extends StatelessWidget {
  const _CompassContent({
    required this.heading,
    required this.direction,
    required this.history,
  });

  final double? heading;
  final String? direction;

  /// Latest direction changes, newest first.
  final List<(String, DateTime)> history;

  @override
  Widget build(BuildContext context) {
    final dial = _dialSize(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SlideUpTitle('Compass'),
        const SizedBox(height: 16),
        // Fixed marker at the top: where the phone is pointing.
        const Icon(Icons.arrow_drop_down, size: 36, color: AppColors.brand),
        SizedBox.square(
          dimension: dial,
          child: CompassDial(heading: heading ?? 0),
        ),
        const SizedBox(height: 20),
        // The live reading, or a waiting line until the first one.
        if (heading != null)
          Text(
            '${heading!.round()}°  $direction',
            key: const Key('compass.reading'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          )
        else
          const Text(
            'Waiting for the compass…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 24),
          // Kept readable in landscape instead of stretching edge to edge.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              key: const Key('compass.recent'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                for (final (dir, time) in history) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            dir,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          formatTime(time),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Compass dial that turns so N always points north. Turning across 0°
/// (e.g. 359° → 1°) goes the short way instead of spinning all the way
/// round.
class CompassDial extends StatefulWidget {
  const CompassDial({super.key, required this.heading});

  /// Degrees, 0 = top of the phone pointing north.
  final double heading;

  @override
  State<CompassDial> createState() => _CompassDialState();
}

class _CompassDialState extends State<CompassDial> {
  /// Total turns so far, unwrapped (can go past 1 or below 0).
  late double _turns = widget.heading / 360;

  @override
  void didUpdateWidget(CompassDial old) {
    super.didUpdateWidget(old);
    final delta = ((widget.heading - old.heading + 540) % 360) - 180;
    _turns += delta / 360;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      // The dial turns the opposite way to the phone.
      turns: -_turns,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: const CustomPaint(painter: _DialPainter()),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Face and rim.
    canvas.drawCircle(c, r, Paint()..color = AppColors.field);
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AppColors.text,
    );

    // Ticks every 5°, longer every 30°.
    for (var deg = 0; deg < 360; deg += 5) {
      final major = deg % 30 == 0;
      final a = deg * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      final outer = c + dir * (r - 8);
      final inner = c + dir * (r - (major ? 22 : 14));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = major ? AppColors.text : AppColors.muted
          ..strokeWidth = major ? 2.5 : 1.2,
      );
    }

    // Degree numbers every 30° (except the four letters).
    for (var deg = 30; deg < 360; deg += 30) {
      if (deg % 90 == 0) continue;
      _label(canvas, c, r - 38, deg, '$deg', 11, AppColors.muted, bold: false);
    }

    // N, E, S, W; N in brand red.
    for (final (deg, text) in [(0, 'N'), (90, 'E'), (180, 'S'), (270, 'W')]) {
      _label(
        canvas,
        c,
        r - 42,
        deg,
        text,
        22,
        deg == 0 ? AppColors.brand : AppColors.text,
        bold: true,
      );
    }

    // Needle: red half points north, dark half south.
    final needle = r * 0.42;
    final w = r * 0.09;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - needle)
        ..lineTo(c.dx + w, c.dy)
        ..lineTo(c.dx - w, c.dy)
        ..close(),
      Paint()..color = AppColors.brand,
    );
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy + needle)
        ..lineTo(c.dx + w, c.dy)
        ..lineTo(c.dx - w, c.dy)
        ..close(),
      Paint()..color = AppColors.text,
    );
    canvas.drawCircle(c, w * 0.6, Paint()..color = Colors.white);
  }

  /// Draws [text] at [deg] around the dial, upright relative to the dial.
  void _label(
    Canvas canvas,
    Offset c,
    double radius,
    int deg,
    String text,
    double fontSize,
    Color color, {
    required bool bold,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final a = deg * math.pi / 180;
    canvas
      ..save()
      ..translate(c.dx + math.sin(a) * radius, c.dy - math.cos(a) * radius)
      ..rotate(a);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
