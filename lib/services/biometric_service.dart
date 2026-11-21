import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric sign-in (Week 6). The phone decides which kind it has: Face ID
/// or Touch ID on iPhone, fingerprint or face unlock on Android.
enum BiometricResult { success, failed, cancelled, unavailable }

/// The biometric this phone offers, as the user knows it.
enum BiometricKind {
  faceId('Face ID', Icons.face),
  touchId('Touch ID', Icons.fingerprint),
  fingerprint('Fingerprint', Icons.fingerprint),
  faceUnlock('Face Unlock', Icons.face),
  // Android reports only "strong"/"weak" on some phones.
  other('Biometrics', Icons.lock_person),
  none('Biometrics', Icons.lock_person);

  const BiometricKind(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get available => this != BiometricKind.none;
  bool get isFace => this == faceId || this == faceUnlock;

  /// Prompt shown in our sheet and by the phone, e.g. "Look at your phone".
  String get instruction => switch (this) {
    faceId || faceUnlock => 'Look at your phone',
    touchId || fingerprint => 'Place your finger on the sensor',
    _ => 'Confirm it’s you',
  };
}

abstract class BiometricService {
  /// Which biometric is set up on this phone (none if not set up).
  Future<BiometricKind> detect();

  Future<BiometricResult> authenticate(String reason);
}

/// Real Face ID / Touch ID / fingerprint via `local_auth`.
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService();

  final _auth = LocalAuthentication();

  @override
  Future<BiometricKind> detect() async {
    try {
      if (!await _auth.isDeviceSupported()) return BiometricKind.none;
      // Only biometrics the user has actually enrolled are listed.
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return BiometricKind.none;
      final ios = Platform.isIOS;
      if (types.contains(BiometricType.face)) {
        return ios ? BiometricKind.faceId : BiometricKind.faceUnlock;
      }
      if (types.contains(BiometricType.fingerprint)) {
        return ios ? BiometricKind.touchId : BiometricKind.fingerprint;
      }
      return BiometricKind.other;
    } on Exception {
      return BiometricKind.none;
    }
  }

  @override
  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => BiometricResult.cancelled,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable => BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } on PlatformException {
      return BiometricResult.unavailable;
    }
  }
}

/// Used in widget tests and on devices without a sensor.
class UnavailableBiometricService implements BiometricService {
  const UnavailableBiometricService();

  @override
  Future<BiometricKind> detect() async => BiometricKind.none;

  @override
  Future<BiometricResult> authenticate(String reason) async =>
      BiometricResult.unavailable;
}
