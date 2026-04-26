import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/models/orders/order_model.dart';
import 'package:rs2_desktop/providers/orders_provider.dart';
import 'package:rs2_desktop/routes/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesSearch = query.isEmpty ||
          order.id.toLowerCase().contains(query) ||
          order.waiterName.toLowerCase().contains(query) ||
          (order.tableNumber ?? '').toLowerCase().contains(query);
      final matchesStatus =
          _selectedStatus == 'All' || order.status == _selectedStatus;
      final matchesType = _selectedType == 'All' || order.type == _selectedType;
      return matchesSearch && matchesStatus && matchesType;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _exportOrdersPdf(List<OrderModel> orders) async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders to export.')),
      );
      return;
    }

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);
    final pdf = pw.Document();
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    final totalAmount = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Orders Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated: $now  |  Orders: ${orders.length}  |  Total: ${_money(totalAmount)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'Order',
              'Waiter',
              'Table',
              'Type',
              'Items',
              'Total',
              'Status',
              'Created',
            ],
            data: orders
                .map(
                  (order) => [
                    _shortId(order.id),
                    order.waiterName,
                    order.tableNumber ?? '-',
                    _formatType(order.type),
                    order.items.fold<int>(0, (sum, item) => sum + item.quantity)
                        .toString(),
                    _money(order.totalAmount),
                    order.status,
                    DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Filters: Status ${_formatType(_selectedStatus)}, Type ${_formatType(_selectedType)}, Search "${_searchController.text.trim().isEmpty ? '-' : _searchController.text.trim()}"',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final filePath =
        '${Directory.systemTemp.path}/orders_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(filePath).writeAsBytes(bytes);
    final opened = await launchUrl(Uri.file(filePath));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the generated PDF file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, provider, _) {
        final orders = _filteredOrders(provider.orders);

        return Container(
          color: AppColors.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              _buildFilters(),
              Expanded(
                child: provider.isLoading && provider.orders.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null && provider.orders.isEmpty
                        ? _buildError(provider)
                        : orders.isEmpty
                            ? _buildEmptyState()
                            : _buildOrdersTable(orders),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(OrdersProvider provider) {
    final filteredOrders = _filteredOrders(provider.orders);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Orders Management',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${provider.orders.length} total orders',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: filteredOrders.isEmpty
                ? null
                : () => _exportOrdersPdf(filteredOrders),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading
                ? null
                : () => context.read<OrdersProvider>().fetchOrders(),
            icon: const Icon(Icons.refresh),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by order ID, waiter, or table...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 170,
            child: _buildDropdown(
              value: _selectedStatus,
              items: const [
                'All',
                'Pending',
                'Preparing',
                'Ready',
                'Completed',
                'Cancelled',
              ],
              onChanged: (value) => setState(() => _selectedStatus = value),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 150,
            child: _buildDropdown(
              value: _selectedType,
              items: const ['All', 'DineIn', 'TakeAway'],
              onChanged: (value) => setState(() => _selectedType = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(_formatType(item)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _buildOrdersTable(List<OrderModel> orders) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor:
                          WidgetStateProperty.all(AppColors.surfaceVariant),
                      columnSpacing: 28,
                      columns: const [
                        DataColumn(label: Text('Order')),
                        DataColumn(label: Text('Waiter')),
                        DataColumn(label: Text('Table')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Created')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: orders.map((order) {
                        return DataRow(
                          cells: [
                            DataCell(Text(_shortId(order.id))),
                            DataCell(Text(order.waiterName)),
                            DataCell(Text(order.tableNumber ?? '-')),
                            DataCell(Text(_formatType(order.type))),
                            DataCell(Text(_money(order.totalAmount))),
                            DataCell(_StatusChip(status: order.status)),
                            DataCell(
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm')
                                    .format(order.createdAt),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Details',
                                icon: const Icon(Icons.visibility_outlined),
                                color: AppColors.primary,
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.adminOrderDetail,
                                  arguments: order,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(OrdersProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            provider.error ?? 'Unable to load orders',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => provider.fetchOrders(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              color: AppColors.textSecondary, size: 52),
          SizedBox(height: 12),
          Text(
            'No orders found',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : '#${id.substring(0, 8)}';

  String _formatType(String type) {
    if (type == 'DineIn') return 'Dine In';
    if (type == 'TakeAway') return 'Take Away';
    return type;
  }

  String _money(double value) => '${value.toStringAsFixed(2)} KM';
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Pending' => AppColors.warning,
      'Preparing' => AppColors.info,
      'Ready' => AppColors.success,
      'Completed' => AppColors.grey,
      'Cancelled' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
