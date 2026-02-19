import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_auth_service.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>(
  (ref) => BiometricAuthService(),
);
