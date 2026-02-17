# MindSpend Mobile App

MindSpend is a Flutter app that helps users make better spending decisions by translating price into real-life impact: time, budget pressure, and tradeoffs.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [User Journey](#user-journey)
- [Calculation Engine](#calculation-engine)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Firebase Setup](#firebase-setup)
- [Build and Test](#build-and-test)
- [Troubleshooting](#troubleshooting)
- [Branding and App Icon](#branding-and-app-icon)
- [Contributing](#contributing)
- [License](#license)

## Overview

Instead of showing only a number, MindSpend reframes each purchase as:

- Work time required to pay for it
- Impact on emergency runway
- Share of monthly expenses consumed
- Contextual insight to reduce impulsive spending

## Features

- Firebase authentication (email/password + Google)
- Email verification flow
- Guest mode without account
- Profile onboarding (income mode, expenses, work settings)
- Purchase check + cool-off + results flow
- Purchase history persistence
  - Firestore for authenticated users
  - SharedPreferences for guests
- Insights, profile, settings, and goals screens
- Adaptive Android and iOS app icons

## Tech Stack

- Flutter (Material 3)
- Riverpod for state management
- GoRouter for navigation and route guards
- Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`)
- `shared_preferences` for guest/local storage

## Project Structure

```text
spending-pain-simulator-mobile-app/
  mobile-app/
    lib/
      app/         # App wiring and router
      features/    # UI screens by feature
      models/      # Domain models
      providers/   # Riverpod providers/notifiers
      services/    # Auth + purchase persistence
      theme/       # Color system + typography
      utils/       # Spending calculations
    android/
    ios/
    test/
```

## User Journey

1. Welcome
2. Sign in or continue as guest
3. Verify email (if required)
4. Complete profile setup (if missing)
5. Use Home tabs: Insights / Check / Profile
6. Run cool-off flow and view result
7. Save decision in purchase history

Routing and auth guards are implemented in `mobile-app/lib/app/router.dart`.

## Calculation Engine

Core formulas are in `mobile-app/lib/utils/calculations.dart`.

- `timeInMinutes = (price / hourlyWage) * 60`
- `emergencyBufferDays = price / (monthlyExpenses / 30)`
- `monthsOfExpenses = price / monthlyExpenses`

The module also handles formatting (`xh ym`, workday/year context, and time-ago labels).

## Prerequisites

- Flutter SDK (stable)
- Android Studio + Android SDK (Android builds)
- Xcode + CocoaPods (iOS builds on macOS)
- A Firebase project with Auth and Firestore enabled

## Quick Start

```bash
cd mobile-app
flutter pub get
flutter run
```

## Firebase Setup

Firebase platform files are intentionally **not tracked in git** and must exist locally:

- `mobile-app/android/app/google-services.json`
- `mobile-app/ios/Runner/GoogleService-Info.plist`

`mobile-app/lib/firebase_options.dart` can stay in source control.

### Running on Another Machine

Yes, you must configure Firebase again (or copy the correct local config files securely).

Recommended setup:

```bash
cd mobile-app
flutterfire configure
```

Then verify generated files are present in the paths above.

## Build and Test

Run inside `mobile-app/`:

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release
```

## Troubleshooting

### CocoaPods Base Configuration Warning

If you see CocoaPods warnings about base configuration, ensure these files include Pods configs:

- `mobile-app/ios/Flutter/Debug.xcconfig`
- `mobile-app/ios/Flutter/Release.xcconfig`

Then run:

```bash
cd mobile-app
flutter clean
flutter pub get
flutter build ios
```

### Android Icon Not Updating

Launcher icons can be cached by the device launcher.

```bash
flutter clean
flutter pub get
flutter run
```

If needed, uninstall/reinstall the app.

## Branding and App Icon

- Android app label: `mobile-app/android/app/src/main/AndroidManifest.xml`
- iOS app display name: `mobile-app/ios/Runner/Info.plist`
- Icon generation config: `mobile-app/pubspec.yaml` (`flutter_launcher_icons`)

## Contributing

1. Create a branch from `main`
2. Implement your changes
3. Run `flutter analyze` and `flutter test`
4. Open a PR with clear context and screenshots if UI changed

## License

No license file is currently defined.
