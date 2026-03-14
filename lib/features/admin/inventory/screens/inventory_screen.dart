import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/inventory/widgets/adjust_inventory_dialog.dart';
import 'package:rs2_desktop/features/admin/inventory/widgets/inventory_logs_dialog.dart';
import 'package:rs2_desktop/models/inventory/store_product_model.dart';
import 'package:rs2_desktop/providers/business_providers.dart';
import 'package:rs2_desktop/features/admin/inventory/widgets/inventory_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'all'; // all, low_stock, out_of_stock
  String _searchQuery = '';
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final inventoryProvider = context.read<InventoryProvider>();
    final storesProvider = context.read<StoresProvider>();

    await Future.wait([
      inventoryProvider.fetchStoreProducts(storeId: _selectedStoreId),
      inventoryProvider.fetchLowStockProducts(),
      inventoryProvider.fetchTotalStockValue(storeId: _selectedStoreId),
      storesProvider.fetchStores(),
    ]);
  }

  Future<void> _exportInventoryPdf(List<StoreProductModel> products) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final pdf = pw.Document();
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Inventory Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 8),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Store', 'Stock', 'Min Stock', 'Unit', 'Purchase Price', 'Status'],
            data: products.map((p) => [
              p.name,
              p.storeName,
              p.currentStock.toString(),
              p.minimumStock.toString(),
              p.unit,
              '\$${p.purchasePrice.toStringAsFixed(2)}',
              p.isLowStock ? 'LOW STOCK' : (p.currentStock == 0 ? 'OUT OF STOCK' : 'OK'),
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              6: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Total items: ${products.length}  |  Low stock: ${products.where((p) => p.isLowStock).length}  |  Out of stock: ${products.where((p) => p.currentStock == 0).length}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final filePath = '${Directory.systemTemp.path}/inventory_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(filePath).writeAsBytes(bytes);
    await Process.run('open', [filePath]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<InventoryProvider, StoresProvider>(
      builder: (context, inventoryProvider, storesProvider, child) {
        if (inventoryProvider.isLoading && inventoryProvider.storeProducts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (inventoryProvider.error != null && inventoryProvider.storeProducts.isEmpty) {
          return _buildError(inventoryProvider.error!);
        }

        return _buildContent(inventoryProvider, storesProvider);
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

  Widget _buildContent(InventoryProvider inventoryProvider, StoresProvider storesProvider) {
    final filteredProducts = _getFilteredProducts(inventoryProvider.storeProducts);

    return Column(
      children: [
        _buildHeader(inventoryProvider, storesProvider),
        const SizedBox(height: 24),
        _buildFilters(inventoryProvider),
        const SizedBox(height: 24),
        Expanded(
          child: filteredProducts.isEmpty
              ? _buildEmptyState()
              : _buildProductsList(filteredProducts),
        ),
      ],
    );
  }

  Widget _buildHeader(InventoryProvider inventoryProvider, StoresProvider storesProvider) {
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
                    'Inventory Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor and manage your stock levels',
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
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _exportInventoryPdf(inventoryProvider.storeProducts),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatsCards(inventoryProvider),
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

  Widget _buildStatsCards(InventoryProvider provider) {
    final totalProducts = provider.storeProducts.length;
    final lowStockCount = provider.lowStockProducts.length;
    final outOfStockCount = provider.storeProducts.where((p) => p.currentStock == 0).length;
    final totalValue = provider.totalStockValue ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Products',
            totalProducts.toString(),
            Icons.inventory_2,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Low Stock',
            lowStockCount.toString(),
            Icons.warning_amber,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Out of Stock',
            outOfStockCount.toString(),
            Icons.remove_circle_outline,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Total Value',
            NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(totalValue),
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

  Widget _buildFilters(InventoryProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildFilterChip('All', 'all', provider.storeProducts.length),
          const SizedBox(width: 8),
          _buildFilterChip('Low Stock', 'low_stock', provider.lowStockProducts.length),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Out of Stock',
            'out_of_stock',
            provider.storeProducts.where((p) => p.currentStock == 0).length,
          ),
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

  List<dynamic> _getFilteredProducts(List products) {
    var filtered = products;

    // Apply filter
    if (_selectedFilter == 'low_stock') {
      filtered = products.where((p) => p.isLowStock && p.currentStock > 0).toList();
    } else if (_selectedFilter == 'out_of_stock') {
      filtered = products.where((p) => p.currentStock == 0).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(_searchQuery) ||
            p.storeName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'No inventory items to display',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List products) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InventoryCard(
              product: product,
              onAdjust: () => _showAdjustDialog(product),
              onViewLogs: () => _showLogsDialog(product),
            ),
          );
        },
      ),
    );
  }

  void _showAdjustDialog(product) {
    showDialog(
      context: context,
      builder: (context) => AdjustInventoryDialog(product: product),
    );
  }

  void _showLogsDialog(product) {
    showDialog(
      context: context,
      builder: (context) => InventoryLogsDialog(productId: product.id),
    );
  }
}