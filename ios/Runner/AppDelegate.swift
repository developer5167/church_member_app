import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let controller = window?.rootViewController as! FlutterViewController
    let flavorChannel = FlutterMethodChannel(
      name: "church_flavor",
      binaryMessenger: controller.binaryMessenger
    )
    flavorChannel.setMethodCallHandler { [weak self] call, result in
      if call.method == "getFlavor" {
        // Read from Info.plist at runtime
        let flavor = Bundle.main.infoDictionary?["AppFlavor"] as? String ?? "lordsChurch"
        result(flavor)
      } else {
        result(FlutterMethodNotImplemented)
      } 
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
