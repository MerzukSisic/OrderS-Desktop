import 'package:flutter/material.dart';
import 'package:rs2_desktop/features/admin/auth/login_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/category_create_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/category_edit_screen.dart';
import 'package:rs2_desktop/features/admin/common/admin_layout_screen.dart';
import 'package:rs2_desktop/features/admin/orders/screens/order_detail_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/product_create_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/product_edit_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/user_create_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/user_edit_screen.dart';
import 'package:rs2_desktop/features/admin/procurement/screens/procurement_checkout_screen.dart';
import 'package:rs2_desktop/features/admin/tables/screens/table_create_screen.dart';
import 'package:rs2_desktop/features/admin/tables/screens/table_edit_screen.dart';
import 'package:rs2_desktop/features/admin/stores/screens/store_create_screen.dart';
import 'package:rs2_desktop/features/admin/stores/screens/store_edit_screen.dart';
import 'package:rs2_desktop/features/admin/stores/screens/store_products_screen.dart';
import 'package:rs2_desktop/features/admin/stores/screens/store_product_create_screen.dart';
import 'package:rs2_desktop/features/admin/stores/screens/store_product_edit_screen.dart';
import 'package:rs2_desktop/models/tables/table_model.dart';
import 'package:rs2_desktop/models/inventory/store_model.dart';
import 'package:rs2_desktop/models/inventory/store_product_model.dart';
import 'package:rs2_desktop/models/orders/order_model.dart';

class AppRouter {
  // Auth Routes
  static const String login = '/login';

  // Admin Main Routes (sa indexom)
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminInventory = '/admin/inventory';
  static const String adminProcurement = '/admin/procurement';
  static const String adminOrders = '/admin/orders';
  static const String adminUsers = '/admin/users';
  static const String adminStatistics = '/admin/statistics';
  static const String adminTables = '/admin/tables';
  static const String adminStores = '/admin/stores';

  // Sub-routes (create/edit)
  static const String adminProductCreate = '/admin/products/create';
  static const String adminProductEdit = '/admin/products/edit';
  static const String adminCategoryCreate = '/admin/categories/create';
  static const String adminCategoryEdit = '/admin/categories/edit';
  static const String adminUserCreate = '/admin/users/create';
  static const String adminUserEdit = '/admin/users/edit';
  static const String adminProcurementCheckout = '/admin/procurement/checkout';
  static const String adminOrderDetail = '/admin/orders/detail';
  static const String adminTableCreate = '/admin/tables/create';
  static const String adminTableEdit = '/admin/tables/edit';
  static const String adminStoreCreate = '/admin/stores/create';
  static const String adminStoreEdit = '/admin/stores/edit';
  static const String adminStoreProducts = '/admin/stores/products';
  static const String adminStoreProductCreate = '/admin/stores/products/create';
  static const String adminStoreProductEdit = '/admin/stores/products/edit';

  /// Map route names to screen indexes
  static int getIndexForRoute(String route) {
    switch (route) {
      case adminDashboard:
        return 0;
      case adminProducts:
        return 1;
      case adminCategories:
        return 2;
      case adminInventory:
        return 3;
      case adminProcurement:
        return 4;
      case adminOrders:
        return 5;
      case adminUsers:
        return 6;
      case adminStatistics:
        return 7;
      case adminTables:
        return 8;
      case adminStores:
        return 9;
      default:
        return 0;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // Main Admin Routes (sa sidebar)
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 0),
        );

      case adminProducts:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 1),
        );

      case adminCategories:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 2),
        );

      case adminInventory:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 3),
        );

      case adminProcurement:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 4),
        );

      case adminOrders:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 5),
        );

      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 6),
        );

      case adminStatistics:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 7),
        );

      case adminTables:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 8),
        );

      case adminStores:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 9),
        );

      // Sub-routes (full screen modals - BEZ sidebar)
      case adminProductCreate:
        return MaterialPageRoute(
          builder: (_) => const ProductCreateScreen(),
          fullscreenDialog: true,
        );

      case adminProductEdit:
        final productId = settings.arguments as String?;
        if (productId == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 1),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProductEditScreen(productId: productId),
          fullscreenDialog: true,
        );

      case adminCategoryCreate:
        return MaterialPageRoute(
          builder: (_) => const CategoryCreateScreen(),
          fullscreenDialog: true,
        );

      case adminCategoryEdit:
        final categoryId = settings.arguments as String?;
        if (categoryId == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 2),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CategoryEditScreen(categoryId: categoryId),
          fullscreenDialog: true,
        );

      case adminUserCreate:
        return MaterialPageRoute(
          builder: (_) => const UserCreateScreen(),
          fullscreenDialog: true,
        );

      case adminUserEdit:
        final userId = settings.arguments as String?;
        if (userId == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 6),
          );
        }
        return MaterialPageRoute(
          builder: (_) => UserEditScreen(userId: userId),
          fullscreenDialog: true,
        );

      case adminProcurementCheckout:
        final orderId = settings.arguments as String?;
        if (orderId == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 4),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProcurementCheckoutScreen(orderId: orderId),
          fullscreenDialog: true,
        );

      case adminOrderDetail:
        final order = settings.arguments as OrderModel?;
        if (order == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 5),
          );
        }
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
          fullscreenDialog: true,
        );

      case adminTableCreate:
        return MaterialPageRoute(
          builder: (_) => const TableCreateScreen(),
          fullscreenDialog: true,
        );

      case adminTableEdit:
        final table = settings.arguments as TableModel?;
        if (table == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 8),
          );
        }
        return MaterialPageRoute(
          builder: (_) => TableEditScreen(table: table),
          fullscreenDialog: true,
        );

      case adminStoreCreate:
        return MaterialPageRoute(
          builder: (_) => const StoreCreateScreen(),
          fullscreenDialog: true,
        );

      case adminStoreEdit:
        final store = settings.arguments as Store?;
        if (store == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 9),
          );
        }
        return MaterialPageRoute(
          builder: (_) => StoreEditScreen(store: store),
          fullscreenDialog: true,
        );

      case adminStoreProducts:
        final store = settings.arguments as Store?;
        if (store == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 9),
          );
        }
        return MaterialPageRoute(
          builder: (_) => StoreProductsScreen(store: store),
          fullscreenDialog: true,
        );

      case adminStoreProductCreate:
        final store = settings.arguments as Store?;
        if (store == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 9),
          );
        }
        return MaterialPageRoute(
          builder: (_) => StoreProductCreateScreen(store: store),
          fullscreenDialog: true,
        );

      case adminStoreProductEdit:
        final product = settings.arguments as StoreProductModel?;
        if (product == null) {
          return MaterialPageRoute(
            builder: (_) => const AdminLayoutScreen(initialIndex: 9),
          );
        }
        return MaterialPageRoute(
          builder: (_) => StoreProductEditScreen(product: product),
          fullscreenDialog: true,
        );

      // Not found
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Route not found: ${settings.name}'),
                ],
              ),
            ),
          ),
        );
    }
  }

  // Helper methods
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static Future<dynamic> navigateAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static Future<dynamic> navigateReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  static Future<dynamic> goToLogin(BuildContext context) {
    return navigateAndRemoveUntil(context, login);
  }
}
