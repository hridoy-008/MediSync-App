# Android Gradle configuration notes

Apply these after `flutter create .` regenerates the `android/` Gradle project.

## android/app/build.gradle (or build.gradle.kts)

```gradle
android {
    compileSdk = 34            // 34+ required by recent plugins
    defaultConfig {
        applicationId = "com.medisync.app"   // keep in sync with AndroidManifest
        minSdk = 26            // Android 8 (PRD/TRD §10: Android 8+)
        targetSdk = 34
        multiDexEnabled = true
    }
    compileOptions {
        // flutter_local_notifications needs core library desugaring
        coreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    coreLibraryDesugaring "com.android.tools:desugar_jdk_libs:2.1.2"
}
```

## Firebase (only if you ran `flutterfire configure`)

- Add the Google services plugin to `android/build.gradle` and
  `android/app/build.gradle` per the FlutterFire setup output.
- Drop the generated `google-services.json` into `android/app/` (gitignored).

If you skip Firebase, the app still runs — `FirebaseService.init()` falls back
to offline-only mode.
