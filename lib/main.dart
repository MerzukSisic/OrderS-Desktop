import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:rs2_desktop/core/theme/app_theme.dart';
import 'package:rs2_desktop/features/admin/auth/login_screen.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';
import 'package:rs2_desktop/providers/business_providers.dart';
import 'package:rs2_desktop/providers/categories_provider.dart';
import 'package:rs2_desktop/providers/procurement_payments_providers.dart';
import 'package:rs2_desktop/providers/products_provider.dart';
import 'package:rs2_desktop/providers/tables_provider.dart';
import 'package:rs2_desktop/providers/users_accompaniments_providers.dart';
import 'package:rs2_desktop/providers/notifications_recommendations_providers.dart';
import 'package:rs2_desktop/routes/app_router.dart';

void main() async {
  // ✅ DODATO: Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ DODATO: Initialize Stripe with your publishable key
  const stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  Stripe.publishableKey = stripeKey;

  runApp(const OrdersDesktopApp());
}

class OrdersDesktopApp extends StatelessWidget {
  const OrdersDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider (must be first)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Business Providers
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => StoresProvider()),
        ChangeNotifierProvider(create: (_) => ProcurementProvider()),

        // ✅ DODATO: Payments Provider
        ChangeNotifierProvider(create: (_) => PaymentsProvider()),

        // Notifications & Recommendations
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),

        // Tables
        ChangeNotifierProvider(create: (_) => TablesProvider()),

        // User Management
        ChangeNotifierProvider(create: (_) => UsersProvider()),

        // Accompaniments
        ChangeNotifierProvider(create: (_) => AccompanimentsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'OrderS Desktop',
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // Initial Route based on auth status
            initialRoute: authProvider.isAuthenticated
                ? AppRouter.adminDashboard
                : AppRouter.login,

            // Route Generator
            onGenerateRoute: AppRouter.generateRoute,

            // Unknown Route Handler
            onUnknownRoute: (settings) {
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            },
          );
        },
      ),
    );
  }
}
