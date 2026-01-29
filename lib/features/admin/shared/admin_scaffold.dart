import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';
import 'package:rs2_desktop/routes/app_router.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final String currentRoute;
  final Color? backgroundColor;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.backgroundColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _Sidebar(currentRoute: currentRoute),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  title: title,
                  actions: actions,
                ),
                
                // Content
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SIDEBAR ====================
class _Sidebar extends StatelessWidget {
  final String currentRoute;

  const _Sidebar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.surface,
      child: Column(
        children: [
          // Logo/Header
          Container(
            height: 80,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'OrderS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.1)),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: AppRouter.adminDashboard,
                  isActive: currentRoute == AppRouter.adminDashboard,
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  route: AppRouter.adminProducts,
                  isActive: currentRoute == AppRouter.adminProducts,
                ),
                _SidebarItem(
                  icon: Icons.category_outlined,
                  label: '',
                  route: AppRouter.adminCategories,
                  isActive: currentRoute == AppRouter.adminCategories,
                ),
                _SidebarItem(
                  icon: Icons.warehouse_outlined,
                  label: 'Inventory',
                  route: AppRouter.adminInventory,
                  isActive: currentRoute == AppRouter.adminInventory,
                ),
                _SidebarItem(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Procurement',
                  route: AppRouter.adminProcurement,
                  isActive: currentRoute == AppRouter.adminProcurement,
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Users',
                  route: AppRouter.adminUsers,
                  isActive: currentRoute == AppRouter.adminUsers,
                ),
                _SidebarItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Statistics',
                  route: AppRouter.adminStatistics,
                  isActive: currentRoute == AppRouter.adminStatistics,
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.1)),
          
          // User profile
          _buildUserProfile(context),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.fullName ?? 'Admin',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.role ?? 'Administrator',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                color: AppColors.error,
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldLogout == true && context.mounted) {
                    await authProvider.logout();
                    if (context.mounted) {
                      AppRouter.goToLogin(context);
                    }
                  }
                },
                tooltip: 'Logout',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== SIDEBAR ITEM ====================
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive 
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive 
                      ? AppColors.primary 
                      : AppColors.textSecondary.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive 
                        ? AppColors.primary 
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TOP BAR ====================
class _TopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const _TopBar({
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface, // ✅ PROMIJENJENO - bilo Colors.white
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}