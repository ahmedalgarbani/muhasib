/// Provides a stable identifier for the current device/installation.
/// The ID is shown to the customer and bound into every license key.
abstract class DeviceIdentityService {
  Future<String> getDeviceId();
}
