# Prompt: run the app with Antigravity (agy)

Paste this into Antigravity, or run it from a terminal in `H:\quran_daily`:

```text
agy -i "<the prompt below on one line>"
```

```text
You are running the Halaqa Flutter app (package com.halaqa.app) for the project owner.
Workspace: H:\quran_daily (branch main). Toolchain: Flutter 3.50.0 / Dart 3.14, Gradle 9.5.0, AGP 9.3.1, compileSdk 37.
Goal: build and launch the app in debug mode on the owner's Android phone (device id RZCTC0TNMRW, Samsung SM A536E) and keep the session alive so the owner can press r (hot reload) and R (hot restart).
Steps:
1. Run `adb devices`. If RZCTC0TNMRW is missing, ask the owner to reconnect the USB cable and allow USB debugging, then stop.
2. Make sure no other `flutter run` is attached to that phone.
3. Run: flutter run -d RZCTC0TNMRW --dart-define-from-file=.env
   The .env file holds the public Supabase URL and anon key and the Google client ids. Never print its contents.
4. If the build fails, read the error, fix the cause (Gradle/AGP/Kotlin/SDK versions, plugin compatibility), rebuild, and explain the fix in one or two sentences. Do not downgrade Flutter or packages: the project constitution requires the latest stable versions.
5. When the app is running, tell the owner it is ready, then keep the session open.
Rules: do not commit or push; do not edit Dart feature code; do not touch supabase/ or assets/quran/; never sign in for the owner or type passwords.
```
