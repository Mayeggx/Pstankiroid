# Pstankidroid

Minimal Android demo app built from `plan.md`.

## Scope

- Kotlin
- Jetpack Compose
- Single activity
- Simple ViewModel state holder
- AnkiDroid install/provider/permission checks
- Deck and note type query through the low-level provider API
- Test note insertion with `ACTION_SEND` fallback when direct API access is unavailable

## Next Steps

1. Point `JAVA_HOME`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, and `GRADLE_USER_HOME` to the `E:` paths from `plan.md`.
2. Install the minimum SDK packages for API 34 and build-tools 34.
3. Run `gradlew.bat assembleDebug` inside this folder.
4. Install the APK to a real device with `adb install`.
5. On the device, install AnkiDroid and grant the database permission when prompted.

## Main Files

- `app/src/main/java/com/mayegg/pstanki/MainActivity.kt`
- `app/src/main/java/com/mayegg/pstanki/MainViewModel.kt`
- `app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt`
