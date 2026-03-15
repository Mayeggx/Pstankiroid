# Pstankidroid Build Error Log

## Purpose

This document records the main issues encountered while bringing the demo to a successful `assembleDebug` build.

## 1. Gradle wrapper lock and partial download state

### Symptom

- Gradle waited on wrapper zip access.
- Wrapper files such as `.zip.lck` and `.zip.part` were left behind.

### Cause

- Earlier interrupted runs left stale lock files and partial downloads in the Gradle wrapper cache.

### Resolution

- Cleared stale wrapper processes.
- Removed stale lock and partial files.
- Reused a local Gradle distribution zip where possible.

## 2. Corrupted Gradle transforms cache

### Symptom

- Build failed with messages like:
  - `Could not read workspace metadata`
  - missing `metadata.bin` under `E:\Gradle\user-home\caches\9.0.0\transforms\...`

### Cause

- Interrupted dependency and transform work left the Gradle transforms cache inconsistent.

### Resolution

- Deleted `E:\Gradle\user-home\caches\9.0.0\transforms`.
- Re-ran the build to regenerate cache state.

## 3. AGP and Gradle version mismatch

### Symptom

- AGP failed with:
  - `Minimum supported Gradle version is 9.1.0. Current version is 9.0.0.`

### Cause

- Project wrapper was still configured to `Gradle 9.0.0`.

### Resolution

- Updated `gradle-wrapper.properties` to `gradle-9.1.0-bin.zip`.
- Ensured the wrapper distribution was available in the expected wrapper cache path.

## 4. Slow downloads

### Symptom

- Wrapper and dependency downloads were too slow.

### Cause

- No Gradle proxy was configured initially.

### Resolution

- Added project-level Gradle proxy settings in `gradle.properties`.
- Added `HTTP_PROXY` and `HTTPS_PROXY` to `scripts\use-e-drive-android-env.ps1`.
- Proxy target:
  - `127.0.0.1:7897`

## 5. Android home preference path conflict

### Symptom

- AGP failed with:
  - `Several environment variables and/or system properties contain different paths to the Android Preferences folder`

### Cause

- `ANDROID_USER_HOME` and `ANDROID_PREFS_ROOT` were both set.
- AGP 9 rejects that combination even when the paths are the same.

### Resolution

- Removed `ANDROID_PREFS_ROOT` from the active env script.
- Kept only `ANDROID_USER_HOME`.

## 6. Kotlin plugin duplication under AGP 9

### Symptom

- Build failed with:
  - `The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0.`

### Cause

- The module still applied `org.jetbrains.kotlin.android`.

### Resolution

- Removed `org.jetbrains.kotlin.android` from:
  - root `build.gradle.kts`
  - app `build.gradle.kts`

## 7. compileSdk too low for resolved dependencies

### Symptom

- `checkDebugAarMetadata` failed because:
  - `androidx.activity:activity-compose:1.10.1`
  - `androidx.core:core-ktx:1.16.0`
  required `compileSdk 35+`

### Cause

- The project was still compiling against API 34.

### Resolution

- Installed `platforms;android-35`.
- Updated `compileSdk` from `34` to `35`.

## 8. Missing Material Components theme dependency

### Symptom

- Resource linking failed with:
  - `resource style/Theme.Material3.DayNight.NoActionBar not found`

### Cause

- XML theme inherited from a Material Components theme not provided by Compose Material3 alone.

### Resolution

- Added:
  - `com.google.android.material:material:1.12.0`

## Final Outcome

- `assembleDebug` succeeded.
- Output APK:
  - `E:\Mega\Pstankiroid\app\build\outputs\apk\debug\app-debug.apk`
