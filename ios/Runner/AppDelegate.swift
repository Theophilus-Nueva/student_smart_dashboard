import Flutter
import UIKit
import UserNotifications
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
    // Week 6 notifications: let flutter_local_notifications present them
    // as banners even while the app is open (iOS hides them otherwise).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
