import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.watch(authServiceProvider).isAdmin();
});

// Auth State Notifier for login/register flows
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signInAnonymously());
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _authService.signInWithEmail(email, password));
  }

  Future<void> createAccount(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _authService.createAccount(email, password, name));
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onVerificationFailed,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          state = const AsyncValue.data(null);
          onCodeSent(verificationId, resendToken);
        },
        onVerificationFailed: (e) {
          state = AsyncValue.error(e, StackTrace.current);
          onVerificationFailed(e);
        },
        onVerificationCompleted: (credential) {
          state = const AsyncValue.data(null);
          onVerificationCompleted(credential);
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithOTP(String verificationId, String smsCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => _authService.signInWithOTP(verificationId, smsCode));
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signOut());
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
