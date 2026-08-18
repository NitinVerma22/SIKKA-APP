# Walkthrough: Sikka Play Production Build Compilation

This document details the walkthrough of compilation and build steps executed to generate production-ready assets for **Sikka Play**.

## 1. Package name and Config Changes
- Updated android package identifier to **`com.sikkaplay.app`** inside:
  - [build.gradle.kts](file:///e:/development/SikkaPlay/android/app/build.gradle.kts) (`namespace` and `applicationId`)
  - [google-services.json](file:///e:/development/SikkaPlay/android/app/google-services.json) (`package_name`)
- Moved Kotlin source code activity:
  - Cleaned directory `android/app/src/main/kotlin/com/example`
  - Created [MainActivity.kt](file:///e:/development/SikkaPlay/android/app/src/main/kotlin/com/sikkaplay/app/MainActivity.kt) in `com.sikkaplay.app` path.

## 2. Extraction of Certificates
Generated release keystore `sikkaplay-release.keystore` inside `android/app/` signed with credentials housed in `key.properties`. Extracted certificate fingerprints for Firebase registration:
- **SHA-1:** `59:07:58:2E:A8:BB:66:12:F8:E6:23:EC:90:59:69:50:DB:77:FC:0A`
- **SHA-256:** `7F:9A:E2:6C:FC:16:19:E2:D8:18:C7:F9:92:E0:4D:F6:55:CB:7D:0C:3D:64:32:62:43:57:9D:3F:D6:10:75:04`

## 3. Rebuild Accomplished
Cleared caches (`flutter clean`) and recompiled all code libraries:
- **Production Signed Release APK:**
  - Path: [app-release.apk](file:///e:/development/SikkaPlay/build/app/outputs/flutter-apk/app-release.apk)
- **Production Signed Release App Bundle (AAB):**
  - Path: [app-release.aab](file:///e:/development/SikkaPlay/build/app/outputs/bundle/release/app-release.aab)
  - Current Compiled Version: `1.0.3+4` (Version Name: `1.0.3`, Build Number/Version Code: `4`)

## 4. Play Store Publishing Fixes (Build Version Code 4)
- Added `<uses-permission android:name="com.google.android.gms.permission.AD_ID" />` to [AndroidManifest.xml](file:///e:/development/SikkaPlay/android/app/src/main/AndroidManifest.xml) to address Google Play Console's Android 13 (API 33+) Advertising ID warnings.
- Incremented app version code in [pubspec.yaml](file:///e:/development/SikkaPlay/pubspec.yaml) and [app_config.dart](file:///e:/development/SikkaPlay/lib/core/config/app_config.dart) to `4` to resolve Google Play upgrade blocking error.
- Successfully re-built the release AAB bundle: [app-release.aab](file:///e:/development/SikkaPlay/build/app/outputs/bundle/release/app-release.aab).
