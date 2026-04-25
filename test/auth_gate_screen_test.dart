import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/features/admin/auth/auth_gate_screen.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';

class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({required bool authenticated, this.delay = Duration.zero})
    : _authenticated = authenticated;

  final Duration delay;
  final bool _authenticated;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<void> initialize() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }
}

void main() {
  testWidgets('Auth gate opens admin content when authenticated', (
    WidgetTester tester,
  ) async {
    final authProvider = FakeAuthProvider(
      authenticated: true,
      delay: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          home: AuthGateScreen(
            loadingBuilder: (_) => const Text('loading'),
            authenticatedBuilder: (_) => const Text('admin-home'),
            unauthenticatedBuilder: (_) => const Text('login-home'),
          ),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('admin-home'), findsOneWidget);
    expect(find.text('login-home'), findsNothing);
  });

  testWidgets('Auth gate opens login content when unauthenticated', (
    WidgetTester tester,
  ) async {
    final authProvider = FakeAuthProvider(
      authenticated: false,
      delay: const Duration(milliseconds: 20),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          home: AuthGateScreen(
            loadingBuilder: (_) => const Text('loading'),
            authenticatedBuilder: (_) => const Text('admin-home'),
            unauthenticatedBuilder: (_) => const Text('login-home'),
          ),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('login-home'), findsOneWidget);
    expect(find.text('admin-home'), findsNothing);
  });
}
