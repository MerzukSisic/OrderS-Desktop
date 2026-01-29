// lib/features/admin/procurement/screens/procurement_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/procurement/widgets/create_procurement_dialog.dart';
import 'package:rs2_desktop/features/admin/procurement/widgets/procurement_card.dart';
import 'package:rs2_desktop/providers/procurement_payments_providers.dart';
import 'package:rs2_desktop/providers/business_providers.dart';
import 'package:rs2_desktop/routes/app_router.dart';
import 'package:intl/intl.dart';

class ProcurementScreen extends StatefulWidget {
  const ProcurementScreen({super.key});

  @override
  State<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  String _selectedFilter = 'all'; // all, pending, paid, received
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final procurementProvider = context.read<ProcurementProvider>();
    final storesProvider = context.read<StoresProvider>();

    await Future.wait([
      procurementProvider.fetchProcurementOrders(storeId: _selectedStoreId),
      storesProvider.fetchStores(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProcurementProvider, StoresProvider>(
      builder: (context, procurementProvider, storesProvider, child) {
        if (procurementProvider.isLoading && procurementProvider.procurementOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (procurementProvider.error != null && procurementProvider.procurementOrders.isEmpty) {
          return _buildError(procurementProvider.error!);
        }

        return _buildContent(procurementProvider, storesProvider);
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error, style: TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProcurementProvider provider, StoresProvider storesProvider) {
    final filteredOrders = _getFilteredOrders(provider.procurementOrders);

    return Column(
      children: [
        _buildHeader(provider, storesProvider),
        const SizedBox(height: 24),
        _buildFilters(provider),
        const SizedBox(height: 24),
        Expanded(
          child: filteredOrders.isEmpty
              ? _buildEmptyState()
              : _buildOrdersList(filteredOrders),
        ),
      ],
    );
  }

  Widget _buildHeader(ProcurementProvider provider, StoresProvider storesProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Procurement Orders',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage supplier orders and inventory procurement',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (storesProvider.stores.isNotEmpty)
                    _buildStoreFilter(storesProvider),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('New Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsCards(provider),
        ],
      ),
    );
  }

  Widget _buildStoreFilter(StoresProvider storesProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<String?>(
        value: _selectedStoreId,
        hint: const Text('All Stores'),
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surfaceVariant,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Stores'),
          ),
          ...storesProvider.stores.map((store) {
            return DropdownMenuItem<String?>(
              value: store.id,
              child: Text(store.name),
            );
          }),
        ],
        onChanged: (value) {
          setState(() {
            _selectedStoreId = value;
          });
          _loadData();
        },
      ),
    );
  }

  Widget _buildStatsCards(ProcurementProvider provider) {
    final totalOrders = provider.procurementOrders.length;
    final pendingCount = provider.pendingOrders.length;
    final paidCount = provider.paidOrders.length;
    final totalAmount = provider.procurementOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Orders',
            totalOrders.toString(),
            Icons.shopping_bag,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pending',
            pendingCount.toString(),
            Icons.pending,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Paid',
            paidCount.toString(),
            Icons.check_circle,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Value',
            NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(totalAmount),
            Icons.attach_money,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ProcurementProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', provider.procurementOrders.length),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending', provider.pendingOrders.length),
          const SizedBox(width: 8),
          _buildFilterChip('Paid', 'paid', provider.paidOrders.length),
          const SizedBox(width: 8),
          _buildFilterChip('Received', 'received', provider.receivedOrders.length),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  List<dynamic> _getFilteredOrders(List orders) {
    switch (_selectedFilter) {
      case 'pending':
        return orders.where((o) => o.status == 'Pending').toList();
      case 'paid':
        return orders.where((o) => o.status == 'Paid').toList();
      case 'received':
        return orders.where((o) => o.status == 'Received').toList();
      default:
        return orders;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No procurement orders',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first procurement order',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: const Icon(Icons.add),
            label: const Text('New Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List orders) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ProcurementCard(
              order: order,
              onTap: () => _navigateToCheckout(order),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateProcurementDialog(),
    );
  }

  void _navigateToCheckout(order) {
    Navigator.pushNamed(
      context,
      AppRouter.adminProcurementCheckout,
      arguments: order.id,
    );
  }
}