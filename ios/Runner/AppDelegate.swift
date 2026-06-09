import Flutter
import UIKit

// CORRECT Flutter + Firebase AppDelegate:
// - Do NOT call FirebaseApp.configure() here.
// - firebase_core Flutter plugin handles Firebase initialization from Dart (main.dart).
// - Calling configure() here causes: "Default app has already been configured" crash.

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.gotchaa.app/security",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "setSecureMode" {
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Required for FCM (Firebase Cloud Messaging) on iOS
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
