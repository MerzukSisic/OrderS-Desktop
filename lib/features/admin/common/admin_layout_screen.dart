import 'package:flutter/material.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/categories/screens/categories_list_screen.dart';
import 'package:rs2_desktop/features/admin/common/admin_sidebar.dart';
import 'package:rs2_desktop/features/admin/dashboard/screens/dashboard_screen.dart';
import 'package:rs2_desktop/features/admin/inventory/screens/inventory_screen.dart';
import 'package:rs2_desktop/features/admin/procurement/screens/procurement_screen.dart';
import 'package:rs2_desktop/features/admin/products/screens/products_list_screen.dart';
import 'package:rs2_desktop/features/admin/statistics/screens/statistics_screen.dart';
import 'package:rs2_desktop/features/admin/users/screens/users_list_screen.dart';


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
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onMenuItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
          // Ovdje možeš dodati dodatne akcije ako treba
        ],
      ),
    );
  }
}