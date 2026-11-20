import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One X/Y/Z sensor reading.
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);

  final double x;
  final double y;
  final double z;

  Vec3 maxAbs(Vec3 o) => Vec3(
    math.max(x.abs(), o.x.abs()),
    math.max(y.abs(), o.y.abs()),
    math.max(z.abs(), o.z.abs()),
  );

  List<double> get values => [x, y, z];

  Map<String, double> toJson() => {'x': x, 'y': y, 'z': z};

  factory Vec3.fromJson(Map<String, dynamic> j) => Vec3(
    (j['x'] as num).toDouble(),
    (j['y'] as num).toDouble(),
    (j['z'] as num).toDouble(),
  );
}

/// Sensor streams (real: `sensors_plus` and `flutter_compass`; tests: fakes).
abstract class SensorSource {
  Stream<Vec3> accelerometer();
  Stream<Vec3> gyroscope();

  /// Compass heading in degrees (0 = top of the phone pointing north).
  Stream<double> heading();
}

class DeviceSensorSource implements SensorSource {
  const DeviceSensorSource();

  // Week 5: accelerometer at a 1-second interval.
  @override
  Stream<Vec3> accelerometer() =>
      accelerometerEventStream(samplingPeriod: const Duration(seconds: 1))
          .map((e) => Vec3(e.x, e.y, e.z));

  @override
  Stream<Vec3> gyroscope() =>
      gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
          .map((e) => Vec3(e.x, e.y, e.z));

  /// The phone's own calibrated heading: on iPhone the one Apple's Compass
  /// app uses (Core Location), on Android the fused rotation sensor. Both
  /// keep themselves calibrated, unlike the raw magnetometer, which on
  /// iPhone includes the phone's own magnetic field and got stuck on SW/W.
  @override
  Stream<double> heading() => (FlutterCompass.events ?? const Stream.empty())
      .map((e) => e.heading)
      .where((h) => h != null)
      .map((h) => (h! % 360 + 360) % 360);
}

/// A saved photo (Week 5 camera / gallery).
class DevicePhoto {
  const DevicePhoto({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.time,
    required this.fromCamera,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime time;
  final bool fromCamera;

  String get sizeLabel => sizeBytes >= 1024 * 1024
      ? '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
      : '${(sizeBytes / 1024).round()} KB';

  Map<String, dynamic> toJson() => {
    'path': path,
    'name': name,
    'size': sizeBytes,
    'time': time.toIso8601String(),
    'camera': fromCamera,
  };

  factory DevicePhoto.fromJson(Map<String, dynamic> j) => DevicePhoto(
    path: j['path'] as String,
    name: j['name'] as String,
    sizeBytes: j['size'] as int,
    time: DateTime.parse(j['time'] as String),
    fromCamera: j['camera'] as bool? ?? false,
  );
}

enum SensorStatus { off, waiting, active, unavailable }

/// Device tab state: photos, live sensor readings, maxima and histories.
class DeviceService extends ChangeNotifier {
  DeviceService(
    this._prefs, {
    this.sensors = const DeviceSensorSource(),
    Future<Directory> Function()? documentsDirectory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  static const _photosKey = 'device.photos';
  static const _maxKey = 'device.maxima';
  static const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];

  final SharedPreferences _prefs;
  final SensorSource sensors;
  final Future<Directory> Function() _documentsDirectory;
  final _picker = ImagePicker();
  final _subs = <StreamSubscription<Object>>[];

  List<DevicePhoto> _photos = [];

  Vec3 accel = Vec3.zero;
  Vec3 accelMax = Vec3.zero;
  final List<Vec3> accelHistory = [];
  Vec3 gyro = Vec3.zero;
  Vec3 gyroPrevious = Vec3.zero;
  Vec3 gyroMax = Vec3.zero;
  double? heading;
  final List<(String, DateTime)> directionHistory = [];
  final Map<String, SensorStatus> status = {
    'Camera': SensorStatus.active,
    'Accelerometer': SensorStatus.off,
    'Gyroscope': SensorStatus.off,
    'Compass': SensorStatus.off,
  };

  /// Newest first.
  List<DevicePhoto> get photos => List.unmodifiable(_photos);
  DevicePhoto? get latestPhoto => _photos.isEmpty ? null : _photos.first;
  bool get sensorsRunning => _subs.isNotEmpty;

  String? get direction =>
      heading == null ? null : directions[((heading! + 22.5) % 360 ~/ 45)];

  void load() {
    final raw = _prefs.getString(_photosKey);
    if (raw != null) {
      try {
        _photos = (jsonDecode(raw) as List<dynamic>)
            .map((e) => DevicePhoto.fromJson(e as Map<String, dynamic>))
            .where((p) => File(p.path).existsSync())
            .toList();
      } on FormatException {
        _photos = [];
      }
    }
    final max = _prefs.getString(_maxKey);
    if (max != null) {
      try {
        final j = jsonDecode(max) as Map<String, dynamic>;
        accelMax = Vec3.fromJson(j['accel'] as Map<String, dynamic>);
        gyroMax = Vec3.fromJson(j['gyro'] as Map<String, dynamic>);
      } on Object {
        // Ignore old or broken data.
      }
    }
  }

  // ---- Camera and gallery -------------------------------------------------

  /// Returns the saved photo, or null if the user cancelled.
  Future<DevicePhoto?> pickPhoto({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (file == null) return null;
    final dir = Directory(
      '${(await _documentsDirectory()).path}${Platform.pathSeparator}photos',
    );
    await dir.create(recursive: true);
    final name = file.name.isEmpty
        ? 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : file.name;
    final saved = await File(file.path).copy(
      '${dir.path}${Platform.pathSeparator}'
      '${DateTime.now().millisecondsSinceEpoch}_$name',
    );
    final photo = DevicePhoto(
      path: saved.path,
      name: name,
      sizeBytes: await saved.length(),
      time: DateTime.now(),
      fromCamera: fromCamera,
    );
    _photos.insert(0, photo);
    if (_photos.length > 20) {
      for (final old in _photos.sublist(20)) {
        unawaited(_deleteFile(old.path));
      }
      _photos = _photos.sublist(0, 20);
    }
    await _savePhotos();
    return photo;
  }

  Future<void> removePhoto(DevicePhoto photo) async {
    _photos.removeWhere((p) => p.path == photo.path);
    await _deleteFile(photo.path);
    await _savePhotos();
  }

  Future<void> _deleteFile(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  Future<void> _savePhotos() async {
    notifyListeners();
    await _prefs.setString(
      _photosKey,
      jsonEncode(_photos.map((p) => p.toJson()).toList()),
    );
  }

  // ---- Sensors ------------------------------------------------------------

  void startSensors() {
    if (_subs.isNotEmpty) return;
    for (final name in ['Accelerometer', 'Gyroscope', 'Compass']) {
      status[name] = SensorStatus.waiting;
    }
    _subs
      ..add(_listen<Vec3>(sensors.accelerometer(), 'Accelerometer', _onAccel))
      ..add(_listen<Vec3>(sensors.gyroscope(), 'Gyroscope', _onGyro))
      ..add(_listen<double>(sensors.heading(), 'Compass', _onHeading));
    notifyListeners();
  }

  void stopSensors() {
    if (_subs.isEmpty) return;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    for (final name in ['Accelerometer', 'Gyroscope', 'Compass']) {
      if (status[name] != SensorStatus.unavailable) {
        status[name] = SensorStatus.off;
      }
    }
    unawaited(
      _prefs.setString(
        _maxKey,
        jsonEncode({'accel': accelMax.toJson(), 'gyro': gyroMax.toJson()}),
      ),
    );
    notifyListeners();
  }

  StreamSubscription<T> _listen<T extends Object>(
    Stream<T> stream,
    String name,
    void Function(T) onData,
  ) {
    return stream.listen(
      (v) {
        status[name] = SensorStatus.active;
        onData(v);
        notifyListeners();
      },
      onError: (Object _) {
        status[name] = SensorStatus.unavailable;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  void _onAccel(Vec3 v) {
    accel = v;
    accelMax = accelMax.maxAbs(v);
    accelHistory.insert(0, v);
    if (accelHistory.length > 10) accelHistory.removeLast();
  }

  void _onGyro(Vec3 v) {
    gyroPrevious = gyro;
    gyro = v;
    gyroMax = gyroMax.maxAbs(v);
  }

  /// 0° when the top of the phone points north.
  void _onHeading(double h) {
    heading = h;
    final dir = direction!;
    if (directionHistory.isEmpty || directionHistory.first.$1 != dir) {
      directionHistory.insert(0, (dir, DateTime.now()));
      if (directionHistory.length > 5) directionHistory.removeLast();
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
