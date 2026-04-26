import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:rs2_desktop/config/env_config.dart';
import 'package:rs2_desktop/core/theme/app_theme.dart';
import 'package:rs2_desktop/features/admin/auth/auth_gate_screen.dart';
import 'package:rs2_desktop/features/admin/auth/login_screen.dart';
import 'package:rs2_desktop/providers/business_providers.dart';
import 'package:rs2_desktop/providers/categories_provider.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';
import 'package:rs2_desktop/providers/procurement_payments_providers.dart';
import 'package:rs2_desktop/providers/products_provider.dart';
import 'package:rs2_desktop/providers/tables_provider.dart';
import 'package:rs2_desktop/providers/users_accompaniments_providers.dart';
import 'package:rs2_desktop/providers/notifications_recommendations_providers.dart';
import 'package:rs2_desktop/providers/orders_provider.dart';
import 'package:rs2_desktop/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final stripeKey = EnvConfig.stripePublishableKey;
  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    await Stripe.instance.applySettings();
  }

  runApp(const OrdersDesktopApp());
}

class OrdersDesktopApp extends StatelessWidget {
  const OrdersDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => StoresProvider()),
        ChangeNotifierProvider(create: (_) => ProcurementProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),

        ChangeNotifierProvider(create: (_) => PaymentsProvider()),

        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),

        ChangeNotifierProvider(create: (_) => TablesProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AccompanimentsProvider()),
      ],
      child: MaterialApp(
        title: 'OrderS Desktop',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,

        home: const AuthGateScreen(),

        onGenerateRoute: AppRouter.generateRoute,

        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        },
      ),
    );
  }
}
