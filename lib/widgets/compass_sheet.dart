import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/device_service.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// Slides up a full compass from the Device tab's Compass card. The dial
/// turns with the phone's live heading while the sheet is open.
Future<void> showCompassSheet(BuildContext context, DeviceService device) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // Full screen width: Material 3 caps sheets at 640 px and centres them,
    // so in landscape a tap beside the sheet closed it. The sheet sits in an
    // Align, so without a minimum width it shrinks to its content; minWidth
    // infinity is clamped to the screen width. The notch is handled inside
    // the sheet instead (see _CompassSheet).
    constraints: const BoxConstraints(minWidth: double.infinity),
    backgroundColor: Colors.white,
    builder: (context) => ListenableBuilder(
      listenable: device,
      builder: (context, _) => _CompassSheet(
        heading: device.heading,
        direction: device.direction,
        history: device.directionHistory,
      ),
    ),
  );
}

class _CompassSheet extends StatelessWidget {
  const _CompassSheet({
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
    final size = MediaQuery.sizeOf(context);
    // The sheet spans the screen; keep its content clear of the notch and
    // the home indicator.
    final insets = MediaQuery.paddingOf(context);
    // Fits portrait and landscape: never taller than about half the screen.
    final dial = math
        .min(size.width - 64, size.height * 0.5)
        .clamp(160.0, 340.0);

    // Opens just tall enough for the compass (title down to the hint line);
    // drag or scroll up to reveal Recent. Sizes are fractions of the space
    // under the drag handle.
    final available = size.height - kMinInteractiveDimension;
    final full =
        (size.height - insets.top - kMinInteractiveDimension) / available;
    final peek = math.min(
      (dial + _peekChrome + insets.bottom) / available,
      full,
    );
    // Nothing to reveal until there's a direction to list.
    final max = history.isEmpty ? peek : full;
    final min = math.min(0.25, peek);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: peek,
      minChildSize: min,
      maxChildSize: max,
      snap: true,
      // Two stops: the compass, then everything.
      snapSizes: [if (peek > min && peek < max) peek],
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          24 + insets.left,
          0,
          24 + insets.right,
          32 + insets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Compass',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Fixed marker at the top: where the phone is pointing.
            const Icon(Icons.arrow_drop_down, size: 36, color: AppColors.brand),
            SizedBox.square(
              dimension: dial,
              child: CompassDial(heading: heading ?? 0),
            ),
            const SizedBox(height: 20),
            // No reading yet: show only the "Waiting…" line below.
            if (heading != null) ...[
              Text(
                '${heading!.round()}°  $direction',
                key: const Key('compass.reading'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              heading == null
                  ? 'Waiting for the compass…'
                  : 'Hold the phone flat and turn to find a direction',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
        ),
      ),
    );
  }

  /// Height of everything in the compass part except the dial: title,
  /// marker, reading and hint, with their gaps and bottom padding.
  static const _peekChrome = 24 + 16 + 36 + 20 + 40 + 6 + 20 + 24.0;
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
