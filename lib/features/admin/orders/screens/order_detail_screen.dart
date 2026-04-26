import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/models/orders/order_model.dart';
import 'package:rs2_desktop/providers/orders_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _changeStatus(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Update Order Status',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Change this order to "$status"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<OrdersProvider>();
    final success = await provider.updateOrderStatus(
      orderId: _order.id,
      status: status,
    );

    if (!mounted) return;
    if (success) {
      setState(() => _order = _order.copyWith(status: status));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update order status'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Cancel Order',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter cancellation reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || reason.isEmpty || !mounted) return;

    final provider = context.read<OrdersProvider>();
    final success = await provider.cancelOrder(orderId: _order.id, reason: reason);
    if (!mounted) return;

    if (success) {
      setState(() => _order = _order.copyWith(status: 'Cancelled'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to cancel order'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Order ${_shortId(_order.id)}'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_order.status != 'Cancelled' && _order.status != 'Completed')
            TextButton.icon(
              onPressed: _cancelOrder,
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              label: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummary(),
            const SizedBox(height: 24),
            _buildStatusActions(),
            const SizedBox(height: 24),
            _buildItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Order Details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              _StatusChip(status: _order.status),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            children: [
              _InfoTile(label: 'Waiter', value: _order.waiterName),
              _InfoTile(label: 'Table', value: _order.tableNumber ?? '-'),
              _InfoTile(label: 'Type', value: _formatType(_order.type)),
              _InfoTile(label: 'Created', value: _date(_order.createdAt)),
              if (_order.completedAt != null)
                _InfoTile(label: 'Completed', value: _date(_order.completedAt!)),
              _InfoTile(label: 'Total', value: _money(_order.totalAmount)),
            ],
          ),
          if ((_order.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Notes',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _order.notes!,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusActions() {
    const statuses = ['Pending', 'Preparing', 'Ready', 'Completed'];
    final isFinalStatus =
        _order.status == 'Cancelled' || _order.status == 'Completed';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: isFinalStatus
          ? Row(
              children: [
                const Text(
                  'Change Status',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 18),
                Icon(
                  _order.status == 'Cancelled'
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _order.status == 'Cancelled'
                      ? 'Cancelled orders cannot be changed.'
                      : 'Completed orders cannot be changed.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            )
          : Row(
        children: [
          const Text(
            'Change Status',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 18),
          ...statuses.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: OutlinedButton(
                onPressed: _order.status == status ||
                        isFinalStatus
                    ? null
                    : () => _changeStatus(status),
                child: Text(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppColors.surfaceVariant),
                    columns: const [
                      DataColumn(label: Text('Product')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Unit')),
                      DataColumn(label: Text('Subtotal')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: _order.items.map((item) {
                      final extras = item.selectedAccompaniments
                          .map((a) => a.extraCharge > 0
                              ? '${a.name} (+${_money(a.extraCharge)})'
                              : a.name)
                          .join(', ');
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName),
                                if (extras.isNotEmpty)
                                  Text(
                                    extras,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          DataCell(Text(item.preparationLocation)),
                          DataCell(Text('${item.quantity}')),
                          DataCell(Text(_money(item.unitPrice))),
                          DataCell(Text(_money(item.subtotal))),
                          DataCell(_StatusChip(status: item.status)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : '#${id.substring(0, 8)}';
  String _money(double value) => '${value.toStringAsFixed(2)} KM';
  String _date(DateTime value) => DateFormat('dd.MM.yyyy HH:mm').format(value);
  String _formatType(String type) =>
      type == 'DineIn' ? 'Dine In' : type == 'TakeAway' ? 'Take Away' : type;
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
