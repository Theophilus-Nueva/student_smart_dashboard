import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint check (Week 6).
enum BiometricResult { success, failed, cancelled, unavailable }

abstract class BiometricService {
  Future<bool> isAvailable();
  Future<BiometricResult> authenticate(String reason);
}

/// Real fingerprint / Face ID via `local_auth`.
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService();

  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Exception {
      return false;
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
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricResult> authenticate(String reason) async =>
      BiometricResult.unavailable;
}
