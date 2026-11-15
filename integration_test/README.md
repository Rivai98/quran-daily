# Offline completion integration test

Run the requested integration target on an attached Android emulator or iOS
simulator:

```powershell
flutter test -d <device-id> integration_test/offline_completion_test.dart
```

The test itself uses the real SQLite cache and sync queue with a fake remote
and fake connectivity stream. To execute the same journey without launching an
app or requiring a device, run its host test entry point:

```powershell
flutter test test/integration_offline_completion_test.dart
```
