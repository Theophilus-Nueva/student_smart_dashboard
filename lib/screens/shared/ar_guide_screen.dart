import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/activity_item.dart';
import '../../models/tour.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../services/device_service.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';

/// Week 7 optional AR campus guide, as a simulated AR view: the live camera
/// with floating location labels placed by compass heading, QR checkpoint
/// scanning (UC001–UC005) to record visits, and the guided route with
/// progress. Works offline; visits upload through the sync queue.
class ArGuideScreen extends StatefulWidget {
  const ArGuideScreen({super.key});

  /// Half of the horizontal field of view used to place labels.
  static const halfFov = 35.0;

  @override
  State<ArGuideScreen> createState() => _ArGuideScreenState();
}

class _ArGuideScreenState extends State<ArGuideScreen> {
  MobileScannerController? _camera;
  DeviceService? _device;
  double? _heading;
  final _lastScan = <String, DateTime>{};
  String? _toast;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_device != null) return;
    final services = AppScope.of(context);
    final device = _device = services.device..addListener(_onSensors);
    // Start after this frame: startSensors() notifies listeners, which must
    // not happen while widgets are building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) device.startSensors();
    });
    if (services.useNativeCamera) {
      _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
    }
  }

  @override
  void dispose() {
    final device = _device?..removeListener(_onSensors);
    // Stop after this frame: stopSensors() notifies other listeners (the
    // Device tab), which must not happen while the tree is being torn down.
    if (device != null) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => device.stopSensors())
        ..scheduleFrame();
    }
    _camera?.dispose();
    super.dispose();
  }

  /// Smooths the compass so labels glide instead of jittering.
  void _onSensors() {
    final raw = _device?.heading;
    if (raw == null || !mounted) return;
    setState(() {
      if (_heading == null) {
        _heading = raw;
      } else {
        final delta = _angleDiff(raw, _heading!);
        _heading = (_heading! + delta * 0.25 + 360) % 360;
      }
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final services = AppScope.of(context);
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null) continue;
      final location = services.tour.byQrCode(code);
      if (location == null) continue;
      final last = _lastScan[location.id];
      if (last != null && DateTime.now().difference(last).inSeconds < 10) {
        continue;
      }
      _lastScan[location.id] = DateTime.now();
      await HapticFeedback.mediumImpact();
      await services.tour.recordVisit(location.id);
      await services.activity.add(
        ActivityKind.visit,
        'Checkpoint ${location.qrCode} · ${location.title}',
        services.sync.online
            ? 'Scanned in the AR guide'
            : 'Saved offline · uploads when you are back online',
      );
      if (!mounted) return;
      setState(() => _toast = '${location.title} checkpoint recorded');
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _toast = null);
      });
    }
  }

  void _showDetails(TourLocation location) {
    final tour = AppScope.of(context).tour;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppAssets.campusPhoto,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              location.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              location.subtitle,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(location.description),
            const SizedBox(height: 8),
            Text(location.hours),
            Text(
              '${location.distanceMeters} m · about ${location.walkMinutes} '
              'min walk · checkpoint ${location.qrCode}',
              style: const TextStyle(color: AppColors.muted),
            ),
            if (tour.isVisited(location.id))
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Visited',
                  style: TextStyle(color: AppColors.online),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                Navigator.of(
                  context,
                ).pushNamed(AppRoutes.locationDetail, arguments: location.id);
              },
              child: const Text('Open Location Details'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final camera = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (camera != null)
            MobileScanner(
              controller: camera,
              onDetect: _onDetect,
              placeholderBuilder: (context) =>
                  const _CameraMessage('Starting camera…', loading: true),
              errorBuilder: (context, error) => _CameraMessage(
                _cameraErrorText(error),
                onRetry:
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? null
                    : () => camera.start(),
              ),
            )
          else
            const ColoredBox(color: Color(0xFF263238)),
          ListenableBuilder(
            listenable: services.tour,
            builder: (context, _) => LayoutBuilder(
              builder: (context, box) => _Labels(
                size: box.biggest,
                heading: _heading,
                onTap: _showDetails,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _TopBar(heading: _heading),
                if (_toast != null) _Toast(text: _toast!),
                const Spacer(),
                const _RoutePanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Signed difference a − b in degrees, in (−180, 180].
double _angleDiff(double a, double b) {
  var d = (a - b) % 360;
  if (d > 180) d -= 360;
  if (d <= -180) d += 360;
  return d;
}

class _Labels extends StatelessWidget {
  const _Labels({
    required this.size,
    required this.heading,
    required this.onTap,
  });

  final Size size;
  final double? heading;
  final ValueChanged<TourLocation> onTap;

  @override
  Widget build(BuildContext context) {
    final tour = AppScope.of(context).tour;
    final next = tour.nextRouteStop;
    final h = heading;
    if (h == null) {
      return const SizedBox();
    }
    final labels = <Widget>[];
    final offscreen = <(TourLocation, double)>[];
    for (final l in tour.locations) {
      final rel = _angleDiff(l.bearingDegrees, h);
      if (rel.abs() > ArGuideScreen.halfFov) {
        offscreen.add((l, rel));
        continue;
      }
      const labelWidth = 150.0;
      final x =
          size.width / 2 +
          rel / ArGuideScreen.halfFov * (size.width / 2 - labelWidth / 2) -
          labelWidth / 2;
      // Nearer places sit lower on screen, like objects closer to you.
      final depth = (l.distanceMeters / 150).clamp(0.0, 1.0);
      final y = size.height * (0.38 - depth * 0.2);
      labels.add(
        Positioned(
          left: x,
          top: y,
          width: labelWidth,
          child: _ArLabel(
            location: l,
            visited: tour.isVisited(l.id),
            isNext: l.id == next?.id,
            onTap: () => onTap(l),
          ),
        ),
      );
    }
    // Edge arrow pointing toward the next stop when it is out of view.
    if (next != null) {
      for (final (l, rel) in offscreen) {
        if (l.id != next.id) continue;
        labels.add(
          Positioned(
            top: size.height * 0.28,
            left: rel < 0 ? 12 : null,
            right: rel > 0 ? 12 : null,
            child: _EdgeHint(location: l, toLeft: rel < 0),
          ),
        );
      }
    }
    return Stack(children: labels);
  }
}

class _ArLabel extends StatelessWidget {
  const _ArLabel({
    required this.location,
    required this.visited,
    required this.isNext,
    required this.onTap,
  });

  final TourLocation location;
  final bool visited;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isNext
        ? AppColors.brand
        : visited
        ? AppColors.online
        : Colors.black87;
    return Semantics(
      button: true,
      label: '${location.title}, ${location.distanceMeters} metres',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent, width: isNext ? 2 : 1),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 8),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '↑ ${location.title} (${location.distanceMeters}m)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: accent,
                    ),
                  ),
                  Text(
                    location.hours,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  Text(
                    visited ? 'Visited · Tap for Details' : 'Tap for Details',
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(width: 2, height: 24, color: Colors.white70),
            const Icon(Icons.circle, size: 8, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _EdgeHint extends StatelessWidget {
  const _EdgeHint({required this.location, required this.toLeft});

  final TourLocation location;
  final bool toLeft;

  @override
  Widget build(BuildContext context) {
    final text = toLeft ? '← ${location.title}' : '${location.title} →';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Next: $text',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.heading});

  final double? heading;

  @override
  Widget build(BuildContext context) {
    final h = heading;
    final dir = h == null
        ? null
        : DeviceService.directions[((h + 22.5) % 360 ~/ 45)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close AR guide',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black38),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AR Campus Guide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 6)],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              h == null ? 'Finding direction…' : '$dir · ${h.round()}°',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.online,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Guided route: current and next stop, distance and walk time, progress,
/// and the Pending Visit Uploads count.
class _RoutePanel extends StatelessWidget {
  const _RoutePanel();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final tour = services.tour;
    final sync = services.sync;
    return ListenableBuilder(
      listenable: Listenable.merge([tour, sync]),
      builder: (context, _) {
        final current = tour.currentRouteStop;
        final next = tour.nextRouteStop;
        final done = tour.routeVisitedCount;
        final total = tour.routeStops.length;
        final pct = (tour.routeProgress * 100).round();
        final pending = tour.pendingCount;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current == null
                    ? 'Start at ${tour.routeStops.first.title}'
                    : 'Current stop: ${current.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                next == null
                    ? 'Route complete. Well done!'
                    : 'Next stop: ${next.title} · ${next.distanceMeters} m · '
                          'about ${next.walkMinutes} min walk',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tour.routeProgress,
                  minHeight: 8,
                  color: AppColors.brand,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$done / $total locations · $pct%',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    pending == 0 ? Icons.cloud_done : Icons.cloud_upload,
                    size: 16,
                    color: pending == 0 ? AppColors.online : AppColors.pending,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pending Visit Uploads: $pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: pending == 0
                            ? AppColors.online
                            : AppColors.pending,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sync.online
                    ? 'Point the camera at a checkpoint QR code to record '
                          'your visit.'
                    : 'Offline: scans are saved on your phone and upload '
                          'when you are back online.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Readable text for a camera failure, including the plugin's own error so
/// problems can be diagnosed from a screenshot.
String _cameraErrorText(MobileScannerException error) {
  final details = error.errorDetails?.message ?? error.errorDetails?.code;
  final base = switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied =>
      'Camera access is off. Turn it on for Smart Campus Tour Guide in your '
          'phone settings to use the AR guide.',
    MobileScannerErrorCode.unsupported =>
      'This device has no camera the AR guide can use.',
    _ => 'The camera could not start.',
  };
  return details == null || details.isEmpty
      ? '$base\n(${error.errorCode.name})'
      : '$base\n(${error.errorCode.name}: $details)';
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage(this.text, {this.loading = false, this.onRetry});

  final String text;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF263238),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white70,
                  ),
                )
              else
                const Icon(
                  Icons.no_photography,
                  color: Colors.white70,
                  size: 40,
                ),
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(140, 44),
                  ),
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Label placement maths, exposed for tests.
@visibleForTesting
double arAngleDiff(double a, double b) => _angleDiff(a, b);
