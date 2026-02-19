# MindSpend Mobile App

MindSpend is a Flutter app that helps users make better spending decisions by translating price into real-life impact: time, budget pressure, and tradeoffs.

## Table of Contents

- [Overview](#overview)
- [Quick Links](#quick-links)
- [Features](#features)
- [Detailed Functionality](#detailed-functionality)
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

## Quick Links

- [Authentication and Access](#authentication-and-access)
- [Session Management and Credential UX](#session-management-and-credential-ux)
- [Profile Avatar Customization](#profile-avatar-customization)
- [Purchase Check and Decision Flow](#purchase-check-and-decision-flow)
- [Insights and History](#insights-and-history)
- [Data Storage and Cleanup](#data-storage-and-cleanup)

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
- Dedicated Security screen for biometric lock controls
- Optional biometric app lock (Face ID on iOS, fingerprint on Android)
- Adaptive Android and iOS app icons

## Detailed Functionality

### Authentication and Access

- Supports Firebase email/password sign-in, email/password sign-up, and Google sign-in.
- Enforces email verification for non-Google accounts before full app access.
- Supports guest mode, allowing full local usage without account creation.
- Uses auth-aware route guards to move users to the right flow (welcome, auth, verification, setup, or home).
- Starts returning users directly in the Check flow (`/home/check`) while still protecting unauthenticated flows.

### Session Management and Credential UX

- Session lifetime is capped (currently 30 minutes) for authenticated users.
- Session start time is recorded on successful auth and cleared on sign out.
- Expired sessions are automatically signed out during auth-state resolution.
- Auth form includes app-level "Remember password" preference.
- System password manager integration is enabled using Flutter autofill (`AutofillGroup`, username/email + password hints, `finishAutofillContext(shouldSave: true)`).
- Optional biometric lock can be enabled from the dedicated Security menu and requires biometric verification at activation time.
- When biometric lock is enabled, app launch requires successful Face ID/fingerprint authentication before entering the app.

### Onboarding and User Profile

- First-time users complete setup with personal finance context:
  - hourly wage
  - working days per year
  - monthly expenses
  - optional emergency fund goal
  - optional freedom goal
- Profile persists to Firestore for authenticated users and SharedPreferences for guests.
- Profile screen shows account identity context (guest/email/google provider).

### Profile Avatar Customization

- Users can customize profile identity with:
  - uploaded gallery photo
  - built-in avatar presets
- Avatar has an inline edit button inside the avatar circle.
- Avatar edit menu supports:
  - upload/reupload photo
  - choose preset avatar
  - delete uploaded photo
- Deleting uploaded photo resets to default avatar state (not previous preset fallback).

### Purchase Check and Decision Flow

- Users input purchase label, price, and category.
- App computes personalized cost-of-life impact and decision context.
- Cool-off flow is integrated to reduce impulse decisions.
- Results can be persisted into purchase history for later review.

### Insights and History

- Insights track per-purchase decisions (`bought`, `skipped`, `undecided`).
- Purchase cards support decision editing with animated state transitions:
  - initial toggle selection
  - compact decision chip view
  - edit back to toggle
- Includes smooth UI transitions and haptic feedback for edit/toggle interactions.
- Decision updates are optimistic to avoid disruptive full-screen loading flashes.
- History cards support deletion.
- Aggregated stats include:
  - total checks
  - total skipped / bought
  - money saved from skipped
  - life-time saved from skipped

### Data Storage and Cleanup

- Authenticated storage:
  - profile under `users/{uid}`
  - purchases under `users/{uid}/purchases`
- Guest storage:
  - profile and purchase history via SharedPreferences
- Save paths include stale-key cleanup:
  - profile saves remove old keys no longer present in current model data
  - purchase saves/updates remove outdated fields (including nested fields)
- Guest-mode cleanup removes local profile, purchase history, and last ethical-check state when guest data is cleared.

### Navigation and App Shell

- Main app shell uses 3 primary tabs: Insights, Check, Profile.
- Routing is centralized in `mobile-app/lib/app/router.dart` with auth/profile-state redirects.
- Includes explicit paths for cool-off, results, settings, and goals.

### Launch and UX Polish

- App bootstrap includes a brief branded loading screen during initialization.
- Supports pull-to-refresh in Insights and focused interaction-level animations.

### Platforms

- Primary Flutter targets configured in the project:
  - Android
  - iOS
  - Windows desktop
  - Web (Edge/Chrome when available)

## Tech Stack

MindSpend is built with **Flutter** using **Material 3**, with **Riverpod** for state management and **go_router** for navigation and route protection.
On the backend side, it uses Firebase services (`firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`) and falls back to `shared_preferences` for guest/local persistence.

The project targets the Flutter stable channel with a Dart SDK constraint of `^3.11.0` (see `mobile-app/pubspec.yaml`).

### Languages

- Dart (primary application language)
- Swift/Objective-C (iOS platform layer generated/managed by Flutter)
- Kotlin/Java (Android platform layer generated/managed by Flutter)
- YAML, XML, and Plist for project/platform configuration

### Detailed Stack Breakdown

#### Core Framework

- **Flutter target:** Flutter stable channel
- **Dart SDK constraint:** `^3.11.0` (from `mobile-app/pubspec.yaml`)
- **UI system:** Material 3 enabled

#### State and Architecture

The codebase follows a feature-first structure under `mobile-app/lib/features/`, which keeps UI concerns grouped by domain.
State is handled through Riverpod patterns (`Provider`, `Notifier`, `AsyncNotifier`), while core business logic is kept in:

- `mobile-app/lib/services/` for app services and persistence interactions
- `mobile-app/lib/utils/` for pure logic and calculations

#### Navigation

Navigation is powered by `go_router` with centralized, auth-aware redirect logic in `mobile-app/lib/app/router.dart`.
Routes are guarded based on user state (unauthenticated, verification required, profile incomplete, guest, ready), ensuring users always land on the right flow.

#### Backend and Data

MindSpend supports both authenticated and guest experiences:

- **Authenticated users:** Firebase Auth + Cloud Firestore
- **Guest users:** local persistence via SharedPreferences

At a high level, Firestore stores user profile and purchase-related history while local mode mirrors key behavior without requiring sign-in.

#### Theming and UI

Theming is tokenized and centralized using `mobile-app/lib/theme/colors.dart` and `mobile-app/lib/theme/app_theme.dart`.
Typography is driven through `google_fonts`, keeping visual consistency across screens while supporting both light and dark themes.

#### Tooling

- **Linting:** `flutter_lints`
- **App icon generation:** `flutter_launcher_icons`
- **iOS build tooling:** CocoaPods/Xcode configuration for iOS builds

#### Build and Release

Development quality and release workflow rely on the tooling above.
For release builds, use the commands in the [Build and Test](#build-and-test) section (`flutter build apk --release`, `flutter build ios --release`).
The project currently uses a single environment setup, with room to introduce dev/prod separation later if needed.

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

### First-Time Setup

After cloning the repository, configure Firebase for your local environment (or provide the required config files securely).

Recommended:

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

## License

No license file is currently defined.
