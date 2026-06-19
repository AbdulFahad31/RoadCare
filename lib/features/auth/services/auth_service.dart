import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/errors/exceptions.dart';

class AuthService {
  final sb.SupabaseClient _supabase;

  AuthService({sb.SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? sb.Supabase.instance.client;

  sb.User? get currentUser => _supabase.auth.currentUser;
  Stream<sb.User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);
  bool get isLoggedIn => _supabase.auth.currentSession != null;
  bool get isAnonymous => false; // Disabled guest login as requested

  String get userId => _supabase.auth.currentUser?.id ?? '';

  String get displayName =>
      _supabase.auth.currentUser?.userMetadata?['displayName'] as String? ??
      _supabase.auth.currentUser?.email?.split('@').first ??
      'User';

  /// Sign in with email/password
  Future<sb.AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_supabaseAuthError(e.message));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Create account with email/password
  Future<sb.AuthResponse> createAccount(
      String email, String password, String name) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'displayName': name,
        },
      );

      return response;
    } on sb.AuthException catch (e) {
      throw AuthException(_supabaseAuthError(e.message));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return false;
      return response['is_admin'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  String _supabaseAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    } else if (lower.contains('user already exists')) {
      return 'An account already exists with this email.';
    } else if (lower.contains('weak-password') ||
        lower.contains('should be at least')) {
      return 'Password must be at least 6 characters.';
    } else if (lower.contains('email') && lower.contains('invalid')) {
      return 'Please enter a valid email address.';
    } else if (lower.contains('too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return message;
  }
}
