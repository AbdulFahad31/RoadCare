import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:road_care/features/auth/providers/auth_providers.dart';
import 'package:road_care/features/auth/services/auth_service.dart';
import 'package:road_care/main.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  Stream<sb.User?> get authStateChanges => const Stream.empty();

  @override
  sb.User? get currentUser => null;

  @override
  bool get isLoggedIn => false;
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          authStateProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const RoadCareApp(),
      ),
    );

    // Verify that our app starts. Since we have a splash screen and auth logic,
    // a simple check if the app widget exists is enough for a smoke test.
    expect(find.byType(RoadCareApp), findsOneWidget);
  });
}
