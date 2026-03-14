import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/categories/screens/categories_list_screen.dart';
import 'package:rs2_desktop/features/admin/common/admin_sidebar.dart';
import 'package:rs2_desktop/features/admin/dashboard/screens/dashboard_screen.dart';
import 'package:rs2_desktop/features/admin/inventory/screens/inventory_screen.dart';
import 'package:rs2_desktop/features/admin/procurement/screens/procurement_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/products_list_screen.dart';
import 'package:rs2_desktop/features/admin/statistics/screens/statistics_screen.dart';
import 'package:rs2_desktop/features/admin/stores/screens/stores_list_screen.dart';
import 'package:rs2_desktop/features/admin/tables/screens/tables_list_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/users_list_screen.dart';
import 'package:rs2_desktop/providers/notifications_recommendations_providers.dart';


class AdminLayoutScreen extends StatefulWidget {
  final int initialIndex;

  const AdminLayoutScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends State<AdminLayoutScreen> {
  late int _currentIndex;

  // Lista svih screen-ova
  final List<Widget> _screens = [
    const DashboardScreen(),      // 0
    const ProductsListScreen(),   // 1
    const CategoriesListScreen(), // 2
    const InventoryScreen(),      // 3
    const ProcurementScreen(),    // 4
    const UsersListScreen(),      // 5
    const StatisticsScreen(),     // 6
    const TablesListScreen(),     // 7
    const StoresListScreen(),     // 8
  ];

  // Lista naslova za svaki screen
  final List<String> _titles = [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  void _onMenuItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showNotificationsDialog(BuildContext context, NotificationsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 420,
          height: 520,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(
                  children: [
                    const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (provider.hasUnread)
                      TextButton(
                        onPressed: () async {
                          await provider.markAllAsRead();
                        },
                        child: const Text('Mark all read'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.notifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('No notifications', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: provider.notifications.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final n = provider.notifications[index];
                              final isRead = n['isRead'] == true;
                              final type = (n['type'] as String?) ?? 'Info';
                              final isLowStock = type == 'LowStock';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isLowStock
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                                  child: Icon(
                                    isLowStock ? Icons.warning_amber_rounded : Icons.notifications_outlined,
                                    color: isLowStock ? Colors.orange : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  n['message'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                tileColor: isRead ? null : Colors.blue.withValues(alpha: 0.04),
                                trailing: isRead
                                    ? null
                                    : Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                onTap: isRead
                                    ? null
                                    : () => provider.markAsRead(n['id'].toString()),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Sidebar - PERSISTENT (nikad se ne refresha)
          AdminSidebar(
            currentIndex: _currentIndex,
            onItemTapped: _onMenuItemTapped,
          ),

          // Right Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Content (IndexedStack drži sve screen-ove u memoriji)
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Consumer<NotificationsProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () => _showNotificationsDialog(context, notifProvider),
                  ),
                  if (notifProvider.hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          notifProvider.unreadCount > 99 ? '99+' : notifProvider.unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}