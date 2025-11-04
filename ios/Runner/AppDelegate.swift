import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    //     // Initialize Google Maps with API key
    // if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
    //    let plist = NSDictionary(contentsOfFile: path),
    //    let apiKey = plist["API_KEY"] as? String {
    //   GMSServices.provideAPIKey(apiKey)
    // } else {
    //   // Fallback to Info.plist
    //   if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
    //     GMSServices.provideAPIKey(apiKey)
    //   }
    // }
    GMSServices.provideAPIKey("AIzaSyAuzjqoVRhu70vqDQKFtDuOnZE6UE6kXVM")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
