import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/models/tables/table_model.dart';
import 'package:rs2_desktop/providers/tables_provider.dart';
import 'package:rs2_desktop/routes/app_router.dart';

class TablesListScreen extends StatefulWidget {
  const TablesListScreen({super.key});

  @override
  State<TablesListScreen> createState() => _TablesListScreenState();
}

class _TablesListScreenState extends State<TablesListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TablesProvider>().fetchTables();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TableModel> _filterTables(List<TableModel> tables) {
    if (_searchQuery.isEmpty) return tables;
    return tables.where((t) {
      return t.tableNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _showDeleteDialog(TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 16),
            const Text('Delete Table', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'Delete table ${table.tableNumber}? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<TablesProvider>().deleteTable(table.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? 'Table deleted' : 'Failed to delete table'),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return AppColors.success;
      case 'Occupied':
        return AppColors.error;
      case 'Reserved':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TablesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.tables.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (provider.error != null && provider.tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(provider.error!, style: TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<TablesProvider>().fetchTables(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filtered = _filterTables(provider.tables);

        return Column(
          children: [
            _buildHeader(provider.tables.length),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_restaurant_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No tables found', style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildTableCard(filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tables Management', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('$total total tables', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 14)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: () => context.read<TablesProvider>().fetchTables(),
              tooltip: 'Refresh',
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRouter.adminTableCreate);
              if (mounted) context.read<TablesProvider>().fetchTables();
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Table'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by table number or location...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    final statusColor = _statusColor(table.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(table.tableNumber, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        title: Row(
          children: [
            Text('Table ${table.tableNumber}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(table.status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('Capacity: ${table.capacity}', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7))),
            ]),
            if (table.location != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(table.location!, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7))),
              ]),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRouter.adminTableEdit, arguments: table);
                if (mounted) context.read<TablesProvider>().fetchTables();
              },
              tooltip: 'Edit',
              color: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _showDeleteDialog(table),
              tooltip: 'Delete',
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}
