import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/auth/login_screen.dart';
import 'package:rs2_desktop/features/admin/common/admin_layout_screen.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';

class AuthGateScreen extends StatefulWidget {
  final WidgetBuilder? authenticatedBuilder;
  final WidgetBuilder? unauthenticatedBuilder;
  final WidgetBuilder? loadingBuilder;

  const AuthGateScreen({
    super.key,
    this.authenticatedBuilder,
    this.unauthenticatedBuilder,
    this.loadingBuilder,
  });

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final Future<void> _initializeFuture;

  @override
  void initState() {
    super.initState();
    _initializeFuture = context.read<AuthProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loadingBuilder?.call(context) ?? _defaultLoadingView();
        }

        final authProvider = context.watch<AuthProvider>();
        if (authProvider.isAuthenticated) {
          return widget.authenticatedBuilder?.call(context) ??
              const AdminLayoutScreen(initialIndex: 0);
        }

        return widget.unauthenticatedBuilder?.call(context) ??
            const LoginScreen();
      },
    );
  }

  Widget _defaultLoadingView() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
