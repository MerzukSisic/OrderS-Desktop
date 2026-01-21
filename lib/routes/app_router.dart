import 'package:flutter/material.dart';
import 'package:rs2_desktop/features/admin/auth/login_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/categories_list_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/category_create_screen.dart';
import 'package:rs2_desktop/features/admin/categories/screens/category_edit_screen.dart';
import 'package:rs2_desktop/features/admin/dashboard/screens/dashboard_screen.dart';
import 'package:rs2_desktop/features/admin/inventory/screens/inventory_screen.dart';
import 'package:rs2_desktop/features/admin/procurement/screens/procurement_checkout_screen.dart';
import 'package:rs2_desktop/features/admin/procurement/screens/procurement_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/product_create_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/product_edit_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/products_list_screen.dart';
import 'package:rs2_desktop/features/admin/statistics/screens/statistics_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/user_create_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/user_edit_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/users_list_screen.dart';

class AppRouter {
  // Auth Routes
  static const String login = '/login';
  
  // Admin Routes
  static const String adminDashboard = '/admin/dashboard';
  
  // Products Routes
  static const String adminProducts = '/admin/products';
  static const String adminProductCreate = '/admin/products/create';
  static const String adminProductEdit = '/admin/products/edit';
  
  // Categories Routes
  static const String adminCategories = '/admin/categories';
  static const String adminCategoryCreate = '/admin/categories/create';
  static const String adminCategoryEdit = '/admin/categories/edit';
  
  // Inventory Routes
  static const String adminInventory = '/admin/inventory';
  
  // Procurement Routes
  static const String adminProcurement = '/admin/procurement';
  static const String adminProcurementCheckout = '/admin/procurement/checkout';
  
  // Users Routes
  static const String adminUsers = '/admin/users';
  static const String adminUserCreate = '/admin/users/create';
  static const String adminUserEdit = '/admin/users/edit';
  
  // Statistics Routes
  static const String adminStatistics = '/admin/statistics';

  /// Generate routes based on settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:
        return _buildRoute(const LoginScreen());

      // Dashboard
      case adminDashboard:
        return _buildRoute(const DashboardScreen());

      // Products
      case adminProducts:
        return _buildRoute(const ProductsListScreen());
      
      case adminProductCreate:
        return _buildRoute(const ProductCreateScreen());
      
      case adminProductEdit:
        final productId = settings.arguments as String?;
        if (productId == null) {
          return _buildRoute(const ProductsListScreen());
        }
        return _buildRoute(ProductEditScreen(productId: productId));

      // Categories
      case adminCategories:
        return _buildRoute(const CategoriesListScreen());
      
      case adminCategoryCreate:
        return _buildRoute(const CategoryCreateScreen());
      
      case adminCategoryEdit:
        final categoryId = settings.arguments as String?;
        if (categoryId == null) {
          return _buildRoute(const CategoriesListScreen());
        }
        return _buildRoute(CategoryEditScreen(categoryId: categoryId));

      // Inventory
      case adminInventory:
        return _buildRoute(const InventoryScreen());

      // Procurement
     case adminProcurement:
      return _buildRoute(const ProcurementScreen());

    case adminProcurementCheckout:
      final orderId = settings.arguments as String?;
      if (orderId == null) {
        // Ako nema orderId, vrati na procurement screen
        return _buildRoute(const ProcurementScreen());
      }
      return _buildRoute(ProcurementCheckoutScreen(orderId: orderId));
          // Users
      case adminUsers:
        return _buildRoute(const UsersListScreen());
      
      case adminUserCreate:
        return _buildRoute(const UserCreateScreen());
      
      case adminUserEdit:
        final userId = settings.arguments as String?;
        if (userId == null) {
          return _buildRoute(const UsersListScreen());
        }
        return _buildRoute(UserEditScreen(userId: userId));

      // Statistics
      case adminStatistics:
        return _buildRoute(const StatisticsScreen());

      // Default / Not Found
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Route not found: ${settings.name}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back or to dashboard
                    },
                    child: const Text('Go to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  /// Build route with custom transition
  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(
      builder: (_) => screen,
    );
  }

  /// Navigate to a named route
  static Future<dynamic> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
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

  /// Replace current route
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

  /// Pop current route
  static void pop(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Pop until a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(
      context,
      ModalRoute.withName(routeName),
    );
  }

  /// Navigate to login screen (logout)
  static Future<dynamic> goToLogin(BuildContext context) {
    return navigateAndRemoveUntil(context, login);
  }
}