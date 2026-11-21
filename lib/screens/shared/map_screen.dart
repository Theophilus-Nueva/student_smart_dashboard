import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/slide_up_sheet.dart';

/// Shared / Map (Week 6): OpenStreetMap centred on you (zoom 16) with Home,
/// School and Workplace markers. The map fills the screen; the location
/// details sit in a slide-up panel over it. Widget tests use the schematic
/// instead, because map tiles need the internet.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final tracker = services.tracker;
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: ListenableBuilder(
        listenable: tracker,
        builder: (context, _) {
          final fix = tracker.fix;
          return LayoutBuilder(
            builder: (context, box) {
              // Collapsed, the panel shows the address and GPS status;
              // drag it up for coordinates and markers. It stays below
              // three quarters of the screen so the map is never hidden.
              final bottom = MediaQuery.paddingOf(context).bottom;
              final peek = ((_peekHeight + bottom) / box.maxHeight).clamp(
                0.15,
                0.5,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: services.useNativeMaps
                        ? _LiveMap(fix: fix)
                        : const _SchematicMap(),
                  ),
                  DraggableScrollableSheet(
                    key: const Key('map.info'),
                    initialChildSize: peek,
                    minChildSize: peek,
                    maxChildSize: 0.75,
                    snap: true,
                    builder: (context, controller) => _InfoPanel(
                      fix: fix,
                      controller: controller,
                      showCredit: services.useNativeMaps,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Height of the collapsed panel above the home indicator: handle,
  /// title, two lines of address and the status / credit line.
  static const _peekHeight = 150.0;
}

/// Slide-up panel over the map: address, GPS status, coordinates and the
/// Home / School / Workplace markers.
class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.fix,
    required this.controller,
    required this.showCredit,
  });

  final LocationFix fix;
  final ScrollController controller;

  /// OpenStreetMap's credit (required by its tile policy). The panel
  /// covers the map's bottom corners, so it is shown here instead.
  final bool showCredit;

  @override
  Widget build(BuildContext context) {
    return SlideUpPanel(
      controller: controller,
      children: [
        const Text(
          'Current location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          fix.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        if (!fix.live) ...[
          const SizedBox(height: 4),
          Text(
            fix.problem == null
                ? 'Waiting for GPS · showing the campus location.'
                : '${fix.problem} · showing the campus location.',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
        if (showCredit) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: const Text(
              '© OpenStreetMap contributors',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Moved here from the Home card.
        Row(
          children: [
            Expanded(
              child: InfoField(
                label: 'Latitude',
                value: fix.latitude.toStringAsFixed(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InfoField(
                label: 'Longitude',
                value: fix.longitude.toStringAsFixed(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InfoField(
                label: 'Accuracy',
                value: '±${fix.accuracyMeters.round()} m',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InfoField(
                label: 'Speed',
                value: '${fix.speedKmh.round()} km/h',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InfoField(
                label: 'Altitude',
                value: '${fix.altitudeMeters.round()} m',
              ),
            ),
          ],
        ),
        const SectionHeader('Markers'),
        for (final m in LocationService.markers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(_iconFor(m.label), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(m.label)),
                Text(
                  '${m.latitude.toStringAsFixed(4)}, '
                  '${m.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LiveMap extends StatefulWidget {
  const _LiveMap({required this.fix});

  final LocationFix fix;

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  final _controller = MapController();
  bool _ready = false;

  LatLng get _me => LatLng(widget.fix.latitude, widget.fix.longitude);

  @override
  void didUpdateWidget(_LiveMap old) {
    super.didUpdateWidget(old);
    final f = widget.fix;
    if (_ready &&
        (f.latitude != old.fix.latitude || f.longitude != old.fix.longitude)) {
      _controller.move(_me, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _me,
        initialZoom: 16,
        onMapReady: () => _ready = true,
      ),
      children: [
        // OpenStreetMap's standard tiles. Their usage policy asks apps to
        // identify themselves (userAgentPackageName) and credit OSM.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.smart_dashboard',
        ),
        MarkerLayer(
          markers: [
            for (final m in LocationService.markers)
              Marker(
                point: LatLng(m.latitude, m.longitude),
                width: 90,
                height: 50,
                alignment: Alignment.topCenter,
                child: _MapPin(label: m.label),
              ),
            Marker(point: _me, width: 22, height: 22, child: const _MeDot()),
          ],
        ),
      ],
    );
  }
}

/// Marker icon with its label (Home, School, Workplace).
class _MapPin extends StatelessWidget {
  const _MapPin({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        Icon(_iconFor(label), color: AppColors.brand, size: 28),
      ],
    );
  }
}

/// Blue "you are here" dot.
class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x551E88E5), blurRadius: 10)],
      ),
    );
  }
}

IconData _iconFor(String label) => switch (label) {
  'Home' => Icons.home,
  'Workplace' => Icons.work,
  _ => Icons.school,
};

class _SchematicMap extends StatelessWidget {
  const _SchematicMap();

  @override
  Widget build(BuildContext context) {
    const markers = LocationService.markers;
    final lats = markers.map((m) => m.latitude);
    final lngs = markers.map((m) => m.longitude);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, box) {
        Offset place(double lat, double lng) {
          const pad = 40.0;
          final x = (lng - minLng) / (maxLng - minLng);
          final y = 1 - (lat - minLat) / (maxLat - minLat);
          return Offset(
            pad + x * (box.maxWidth - 2 * pad),
            pad + y * (box.maxHeight - 2 * pad),
          );
        }

        const fix = LocationService.campus;
        final me = place(fix.latitude, fix.longitude);
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _StreetsPainter())),
            for (final m in markers)
              Positioned(
                left: place(m.latitude, m.longitude).dx - 40,
                top: place(m.latitude, m.longitude).dy - 34,
                width: 80,
                child: Column(
                  children: [
                    Icon(_iconFor(m.label), color: AppColors.brand, size: 28),
                    Text(
                      m.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              left: me.dx - 9,
              top: me.dy + 18,
              child: const SizedBox(width: 18, height: 18, child: _MeDot()),
            ),
          ],
        );
      },
    );
  }
}

class _StreetsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFEDE6),
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 10;
    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    // Governor's Drive (diagonal) plus a simple street grid.
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.35),
      road,
    );
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
