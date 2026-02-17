# MindSpend App (mobile-app)

This folder contains the Flutter mobile client for MindSpend.

For full documentation (architecture, features, troubleshooting, and contribution guide), see:

- `../README.md`

## Quick Start

```bash
flutter pub get
flutter run
```

## Firebase (Required)

These files are required locally and are git-ignored:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

If you are on a new machine, configure Firebase before running:

```bash
flutterfire configure
```

## Useful Commands

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release
```
