import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/auth_service.dart';
import '../models/user_profile.dart';

/// Singleton auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream of Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// Whether user is in guest mode
final isGuestProvider = NotifierProvider<IsGuestNotifier, bool>(
  IsGuestNotifier.new,
);

class IsGuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    state = value;
  }
}

/// User profile (loaded from Firestore or SharedPreferences)
final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  ProfileNotifier.new,
);

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return _loadProfile();
  }

  Future<UserProfile?> _loadProfile() async {
    final authState = ref.read(authStateProvider);
    final isGuest = ref.read(isGuestProvider);
    final service = ref.read(authServiceProvider);

    final user = authState.value;
    if (user != null) {
      return await service.loadProfile(user.uid);
    } else if (isGuest) {
      return await service.loadGuestProfile();
    }
    return null;
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadProfile());
  }

  Future<void> saveProfile(UserProfile profile) async {
    final authState = ref.read(authStateProvider);
    final isGuest = ref.read(isGuestProvider);
    final service = ref.read(authServiceProvider);

    final user = authState.value;
    if (user != null) {
      await service.saveProfile(user.uid, profile);
    } else if (isGuest) {
      await service.saveGuestProfile(profile);
    }

    state = AsyncValue.data(profile);
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Auth state helper
enum AppAuthState {
  loading,
  unauthenticated,
  needsVerification,
  needsProfile,
  ready,
  guest,
}

final appAuthStateProvider = Provider<AppAuthState>((ref) {
  final authState = ref.watch(authStateProvider);
  final isGuest = ref.watch(isGuestProvider);
  final profileState = ref.watch(profileProvider);

  if (isGuest) {
    final profile = profileState.value;
    if (profile != null) return AppAuthState.guest;
    return AppAuthState.needsProfile;
  }

  return authState.when(
    loading: () => AppAuthState.loading,
    error: (_, _) => AppAuthState.unauthenticated,
    data: (user) {
      if (user == null) return AppAuthState.unauthenticated;

      // Check email verification (skip for Google users)
      final isGoogleUser = user.providerData.any(
        (p) => p.providerId == 'google.com',
      );
      if (!isGoogleUser && !user.emailVerified) {
        return AppAuthState.needsVerification;
      }

      return profileState.when(
        loading: () => AppAuthState.loading,
        error: (_, _) => AppAuthState.needsProfile,
        data: (profile) {
          if (profile == null) return AppAuthState.needsProfile;
          return AppAuthState.ready;
        },
      );
    },
  );
});
