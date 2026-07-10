# iOS Info.plist additions

After running `flutter create .`, merge these keys into `ios/Runner/Info.plist`
(inside the top-level `<dict>`). They cover prescription capture and the
notification path (TRD §6 iOS section).

```xml
<key>NSCameraUsageDescription</key>
<string>MediSync uses the camera to read your prescriptions.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MediSync needs photo access to import prescription images.</string>

<!-- Background fetch to top up the rolling 64-notification window (TRD §6) -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

## AppDelegate (ios/Runner/AppDelegate.swift)

Register the notification plugin so background actions are delivered:

```swift
import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```
