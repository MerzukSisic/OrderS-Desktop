import 'package:flutter/material.dart';
import 'package:rs2_desktop/features/admin/auth/login_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/category_create_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/category_edit_screen.dart';
import 'package:rs2_desktop/features/admin/common/admin_layout_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/product_create_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/product_edit_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/user_create_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/user_edit_screen.dart';
import 'package:rs2_desktop/features/admin/procurement/screens/procurement_checkout_screen.dart';

class AppRouter {
  // Auth Routes
  static const String login = '/login';

  // Admin Main Routes (sa indexom)
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminCategories = '/admin/categories';
  static const String adminInventory = '/admin/inventory';
  static const String adminProcurement = '/admin/procurement';
  static const String adminUsers = '/admin/users';
  static const String adminStatistics = '/admin/statistics';

  // Sub-routes (create/edit)
  static const String adminProductCreate = '/admin/products/create';
  static const String adminProductEdit = '/admin/products/edit';
  static const String adminCategoryCreate = '/admin/categories/create';
  static const String adminCategoryEdit = '/admin/categories/edit';
  static const String adminUserCreate = '/admin/users/create';
  static const String adminUserEdit = '/admin/users/edit';
  static const String adminProcurementCheckout = '/admin/procurement/checkout';

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
      case adminUsers:
        return 5;
      case adminStatistics:
        return 6;
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

      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 5),
        );

      case adminStatistics:
        return MaterialPageRoute(
          builder: (_) => const AdminLayoutScreen(initialIndex: 6),
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
            builder: (_) => const AdminLayoutScreen(initialIndex: 5),
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