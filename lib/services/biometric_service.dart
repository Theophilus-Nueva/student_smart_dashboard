/// Fingerprint check (Week 6). The real implementation uses `local_auth`,
/// which is added in a later step once the package and the Android/iOS
/// permission changes are approved.
enum BiometricResult { success, failed, unavailable }

abstract class BiometricService {
  Future<bool> isAvailable();
  Future<BiometricResult> authenticate(String reason);
}

/// Used until `local_auth` is added: reports that no sensor is available.
class UnavailableBiometricService implements BiometricService {
  const UnavailableBiometricService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricResult> authenticate(String reason) async =>
      BiometricResult.unavailable;
}
