import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/features/admin/common/admin_sidebar.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';

void main() {
  testWidgets('Admin sidebar menu taps call expected index', (
    WidgetTester tester,
  ) async {
    int? tappedIndex;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AdminSidebar(
              currentIndex: 0,
              onItemTapped: (index) => tappedIndex = index,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Products'));
    await tester.pump();
    expect(tappedIndex, 1);

    await tester.tap(find.text('Procurement'));
    await tester.pump();
    expect(tappedIndex, 4);

    await tester.tap(find.text('Orders'));
    await tester.pump();
    expect(tappedIndex, 5);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Stores'));
    await tester.tap(find.text('Stores'));
    await tester.pump();
    expect(tappedIndex, 9);
  });
}
