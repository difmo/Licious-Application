import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsApiKey = ProcessInfo.processInfo.environment["MAPS_API_KEY"] ?? "AIzaSyCk_tlkrY3-rFWVn6UJ32uzKu50zau2WZQ"
    GMSServices.provideAPIKey(mapsApiKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }


  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
