import Flutter
import UIKit
#if canImport(GoogleMaps)
import GoogleMaps
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if canImport(GoogleMaps)
    // Week 6 map. Set MAPS_API_KEY in ios/Flutter/Secrets.xcconfig.
    let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    GMSServices.provideAPIKey(key.isEmpty ? "MISSING_MAPS_API_KEY" : key)
    #endif
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
