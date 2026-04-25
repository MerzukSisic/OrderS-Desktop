import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/features/admin/procurement/widgets/create_procurement_dialog.dart';
import 'package:rs2_desktop/models/inventory/store_product_model.dart';
import 'package:rs2_desktop/providers/business_providers.dart';

StoreProductModel _fakeProduct() {
  return StoreProductModel(
    id: 'product-1',
    storeId: 'store-1',
    storeName: 'Main Store',
    name: 'Flour',
    purchasePrice: 4.5,
    currentStock: 50,
    minimumStock: 10,
    unit: 'kg',
    isLowStock: false,
    lastRestocked: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('invalid decimal keeps Add button disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<InventoryProvider>(
        create: (_) => InventoryProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AddProcurementItemDialog(
              availableProducts: [_fakeProduct()],
              onAdd: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('add_item_product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flour').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('add_item_quantity')), '2');
    await tester.enterText(find.byKey(const Key('add_item_unit_cost')), ',');
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('add_item_submit')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('valid decimal enables Add and submits parsed values', (
    WidgetTester tester,
  ) async {
    Map<String, dynamic>? addedItem;

    await tester.pumpWidget(
      ChangeNotifierProvider<InventoryProvider>(
        create: (_) => InventoryProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AddProcurementItemDialog(
              availableProducts: [_fakeProduct()],
              onAdd: (item) => addedItem = item,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('add_item_product')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flour').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('add_item_quantity')), '3');
    await tester.enterText(
      find.byKey(const Key('add_item_unit_cost')),
      '12.50',
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('add_item_submit')),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('add_item_submit')));
    await tester.pumpAndSettle();

    expect(addedItem, isNotNull);
    expect(addedItem!['quantity'], 3);
    expect(addedItem!['unitCost'], 12.5);
    expect(addedItem!['storeProductId'], 'product-1');
  });
}
