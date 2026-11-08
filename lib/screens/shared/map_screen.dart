import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/app_services.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

/// Shared / Map (Week 6): Google Map centred on you (zoom 16) with Home,
/// School and Workplace markers. Widget tests use the schematic instead,
/// because the native map view can't run there.
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: services.useNativeMaps
                      ? _LiveMap(fix: fix)
                      : const _SchematicMap(),
                ),
              ),
              if (!fix.live) ...[
                const SizedBox(height: 8),
                Text(
                  fix.problem == null
                      ? 'Waiting for GPS · showing the campus location.'
                      : '${fix.problem} · showing the campus location.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              const SectionHeader('Current location'),
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
        },
      ),
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
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(_LiveMap old) {
    super.didUpdateWidget(old);
    final f = widget.fix;
    if (f.latitude != old.fix.latitude || f.longitude != old.fix.longitude) {
      _controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(f.latitude, f.longitude)),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fix = widget.fix;
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(fix.latitude, fix.longitude),
        zoom: 16,
      ),
      onMapCreated: (c) => _controller = c,
      myLocationEnabled: fix.live,
      myLocationButtonEnabled: fix.live,
      markers: {
        for (final m in LocationService.markers)
          Marker(
            markerId: MarkerId(m.label),
            position: LatLng(m.latitude, m.longitude),
            infoWindow: InfoWindow(title: m.label),
          ),
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(fix.latitude, fix.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      },
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
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x551E88E5), blurRadius: 10),
                  ],
                ),
              ),
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
