import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/activity_item.dart';
import '../../models/tour.dart';
import '../../routes/app_routes.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/location_photo.dart';
import '../../widgets/slide_up_sheet.dart';

/// Week 7 optional AR campus guide, as a simulated AR view. Each key campus
/// location has its own printed QR code (UC001–UC006, see docs/qr_codes);
/// when the camera detects one, that location's information is pinned over
/// the code and the visit is recorded. The guided route and progress are
/// shown while no code is in view. Works offline; visits
/// upload through the sync queue.
class ArGuideScreen extends StatefulWidget {
  const ArGuideScreen({super.key});

  @override
  State<ArGuideScreen> createState() => ArGuideScreenState();
}

@visibleForTesting
class ArGuideScreenState extends State<ArGuideScreen> {
  /// Gap between QR checks, in milliseconds.
  static const scanIntervalMs = 25;

  /// How long the info card stays after the code leaves the camera view.
  static const holdTime = Duration(milliseconds: 1500);

  MobileScannerController? _camera;
  bool _started = false;
  final _lastScan = <String, DateTime>{};
  String? _toast;
  bool _toastIsError = false;
  Timer? _toastTimer;

  /// The checkpoint currently in view, and where its code sits on screen
  /// (null when the position is unknown: the card is then centred).
  TourLocation? _detected;
  Rect? _codeRect;
  Timer? _hideTimer;
  Size _viewSize = Size.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final services = AppScope.of(context);
    if (services.useNativeCamera) {
      _camera = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        // About 40 checks a second (the default 250 ms made the card lag
        // behind the code). Not `unrestricted`, which the package warns can
        // run out of memory on older phones.
        detectionTimeoutMs: scanIntervalMs,
      );
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _hideTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;
      if (code == null) continue;
      handleCode(code, _toScreen(barcode.corners, capture.size));
      return;
    }
  }

  Rect? _toScreen(List<Offset> corners, Size image) =>
      codeRectOnScreen(corners, image, _viewSize);

  /// Maps the code's corners from camera-image pixels to screen points. The
  /// preview fills the screen (BoxFit.cover), so the image is scaled up and
  /// cropped evenly on two sides.
  ///
  /// On iPhone the scanner always reports the image size in portrait, even
  /// when the phone is held sideways, so the size is flipped whenever its
  /// orientation doesn't match the screen's (as mobile_scanner's own overlay
  /// does). The result is kept on screen so the brackets never vanish.
  @visibleForTesting
  static Rect? codeRectOnScreen(List<Offset> corners, Size image, Size view) {
    if (corners.isEmpty || image.isEmpty || view.isEmpty) return null;
    final viewLandscape = view.width > view.height;
    final imageLandscape = image.width > image.height;
    if (viewLandscape != imageLandscape) image = image.flipped;
    final scale = (view.width / image.width) > (view.height / image.height)
        ? view.width / image.width
        : view.height / image.height;
    final dx = (view.width - image.width * scale) / 2;
    final dy = (view.height - image.height * scale) / 2;
    final points = [
      for (final c in corners) Offset(c.dx * scale + dx, c.dy * scale + dy),
    ];
    var rect = Rect.fromPoints(points.first, points.first);
    for (final p in points.skip(1)) {
      rect = rect.expandToInclude(Rect.fromPoints(p, p));
    }
    // Keep the whole box on screen (shift, don't shrink).
    final w = rect.width.clamp(1.0, view.width);
    final h = rect.height.clamp(1.0, view.height);
    return Rect.fromLTWH(
      rect.left.clamp(0.0, view.width - w),
      rect.top.clamp(0.0, view.height - h),
      w,
      h,
    );
  }

  /// A QR code was read: show the location it belongs to over the code and
  /// record the visit (at most once every 10 seconds per location).
  @visibleForTesting
  Future<void> handleCode(String code, [Rect? codeRect]) async {
    final services = AppScope.of(context);
    final location = services.tour.byQrCode(code);
    if (location == null) {
      _showToast('Not a campus checkpoint QR code', error: true);
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(holdTime, () {
      if (mounted) setState(() => _detected = _codeRect = null);
    });
    final isNew = _detected?.id != location.id;
    setState(() {
      _detected = location;
      _codeRect = codeRect;
    });

    final last = _lastScan[location.id];
    if (last != null && DateTime.now().difference(last).inSeconds < 10) return;
    _lastScan[location.id] = DateTime.now();
    if (isNew) unawaited(HapticFeedback.mediumImpact());
    final firstVisit = !services.tour.isVisited(location.id);
    await services.tour.recordVisit(location.id);
    await services.activity.add(
      ActivityKind.visit,
      'Checkpoint ${location.qrCode} · ${location.title}',
      services.sync.online
          ? 'Scanned in the AR guide'
          : 'Saved offline · uploads when you are back online',
    );
    if (firstVisit) _showToast('${location.title} added to your visits');
  }

  void _showToast(String text, {bool error = false}) {
    if (!mounted) return;
    _toastTimer?.cancel();
    setState(() {
      _toast = text;
      _toastIsError = error;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _showDetails(TourLocation location) {
    final tour = AppScope.of(context).tour;
    showSlideUpSheet<void>(
      context,
      children: (sheetContext) => [
        LocationPhoto(location: location, height: 140),
        const SizedBox(height: 12),
        Text(
          location.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(location.subtitle, style: const TextStyle(color: AppColors.muted)),
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
            child: Text('Visited', style: TextStyle(color: AppColors.online)),
          ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(sheetContext);
            Navigator.of(context)
                .pushNamed(AppRoutes.locationDetail, arguments: location.id);
          },
          child: const Text('Open Location Details'),
        ),
      ],
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
              builder: (context, box) {
                _viewSize = box.biggest;
                final detected = _detected;
                // A detected code takes over the view; otherwise the scan
                // frame shows where to aim.
                if (detected != null) {
                  return _CheckpointOverlay(
                    size: box.biggest,
                    location: detected,
                    codeRect: _codeRect,
                    visited: services.tour.isVisited(detected.id),
                    onTap: () => _showDetails(detected),
                  );
                }
                return const _ScanFrame();
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const _TopBar(),
                if (_toast != null) _Toast(text: _toast!, error: _toastIsError),
                const Spacer(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _detected == null
                      ? const _RoutePanel()
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: error ? Colors.black87 : AppColors.online,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            error ? Icons.qr_code_2 : Icons.check_circle,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
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
        final pending = tour.pendingVisitCount;
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
                    ? 'Point the camera at a location\'s QR code to see its '
                          'information and record your visit.'
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

/// Corner brackets in the middle of the view showing where to aim.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: _BracketPainter(Colors.white70)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Scan a location QR code',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws four L-shaped corners around the box it is given.
class _BracketPainter extends CustomPainter {
  const _BracketPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final len = size.shortestSide * 0.22;
    final w = size.width, h = size.height;
    for (final (o, dx, dy) in [
      (Offset.zero, 1.0, 1.0),
      (Offset(w, 0), -1.0, 1.0),
      (Offset(0, h), 1.0, -1.0),
      (Offset(w, h), -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(o, o.translate(len * dx, 0), paint)
        ..drawLine(o, o.translate(0, len * dy), paint);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}

/// The AR part of a scan: red brackets locked onto the detected code and
/// the location's information card pinned just above it (or below, when
/// the code is near the top of the screen).
class _CheckpointOverlay extends StatelessWidget {
  const _CheckpointOverlay({
    required this.size,
    required this.location,
    required this.codeRect,
    required this.visited,
    required this.onTap,
  });

  final Size size;
  final TourLocation location;
  final Rect? codeRect;
  final bool visited;
  final VoidCallback onTap;

  static const cardWidth = 290.0;
  static const cardHeight = 236.0;

  @override
  Widget build(BuildContext context) {
    final rect = codeRect?.inflate(10);
    final width = cardWidth.clamp(0.0, size.width - 24);
    final landscape = size.width > size.height;
    // Highest top that still fits the card (never below the minimum).
    double clampTop(double t, double min) =>
        t.clamp(min, (size.height - cardHeight - 12).clamp(min, size.height));
    double left, top;
    if (rect == null) {
      left = (size.width - width) / 2;
      top = clampTop(size.height * 0.3, 60);
    } else if (landscape) {
      // Sideways there is no room above the code: put the card beside it,
      // on whichever side has more space.
      final roomRight = size.width - rect.right;
      left = roomRight >= rect.left ? rect.right + 16 : rect.left - width - 16;
      left = left.clamp(
        12.0,
        (size.width - width - 12).clamp(12.0, size.width),
      );
      top = clampTop(rect.center.dy - cardHeight / 2, 12);
    } else {
      left = (rect.center.dx - width / 2).clamp(
        12.0,
        (size.width - width - 12).clamp(12.0, size.width),
      );
      final above = rect.top - cardHeight - 16;
      top = clampTop(above > 90 ? above : rect.bottom + 16, 90);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (rect != null)
          AnimatedPositioned(
            duration: const Duration(
              milliseconds: ArGuideScreenState.scanIntervalMs,
            ),
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: const IgnorePointer(
              child: CustomPaint(painter: _BracketPainter(AppColors.brand)),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(
            milliseconds: ArGuideScreenState.scanIntervalMs,
          ),
          left: left,
          top: top,
          width: width,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(location.id),
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Transform.scale(
              scale: t,
              child: Opacity(
                opacity: ((t - 0.85) / 0.15).clamp(0, 1),
                child: child,
              ),
            ),
            child: _CheckpointCard(
              location: location,
              visited: visited,
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckpointCard extends StatelessWidget {
  const _CheckpointCard({
    required this.location,
    required this.visited,
    required this.onTap,
  });

  final TourLocation location;
  final bool visited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${location.title} checkpoint. Tap for details.',
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: AppColors.brand,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Checkpoint ${location.qrCode}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (visited)
                      const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Visited',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      location.subtitle,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.hours,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap for Details',
                      style: TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
