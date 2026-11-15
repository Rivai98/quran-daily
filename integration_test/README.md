# Integration Tests

This directory contains end-to-end integration journeys running against attached devices or emulators.

## Prerequisites

- An attached Android device/emulator (API 26+) or iOS simulator (iOS 15+, macOS only).
- Device ID from `flutter devices`.
- Valid `.env` configuration file passed via `--dart-define-from-file=.env`.

## Available Tests

### 1. Group Flow E2E (`group_flow_test.dart`)

Validates the full user journey against the hosted Supabase DEV database:
1. Sign up (owner account created via UI).
2. Create group (forming state, owner is seat 1).
3. Second test user joins using the generated invite code.
4. Owner starts the khatma with juz 1.
5. Owner opens today's wird and marks it complete.
6. Owner undoes completion via the confirmation sheet.
7. Opens history view.

**Command**:
```bash
flutter test integration_test/group_flow_test.dart -d <device-id> --dart-define-from-file=.env
```

### 2. Offline Completion Journey (`offline_completion_test.dart`)

Validates the offline personal loop (Constitution Principle I):
1. Cached dashboard opened in airplane mode.
2. Mark wird complete offline (optimistic UI update + sync queue row recorded).
3. Reconnect to network and trigger sync.
4. Server confirms completion state.

**Command on Device**:
```bash
flutter test integration_test/offline_completion_test.dart -d <device-id> --dart-define-from-file=.env
```

**Host-Only Execution (No Device Required)**:
To run the exact same offline loop using real SQLite caching and sync queue on your development machine:
```bash
flutter test test/integration_offline_completion_test.dart
```

## Running the App Directly on a Phone

To launch and test the application interactively on an attached phone:
```bash
flutter run -d <device-id> --dart-define-from-file=.env
```
