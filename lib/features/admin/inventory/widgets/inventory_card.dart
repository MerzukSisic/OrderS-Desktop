// lib/features/admin/inventory/widgets/inventory_card.dart
import 'package:flutter/material.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class InventoryCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onAdjust;
  final VoidCallback onViewLogs;

  const InventoryCard({
    super.key,
    required this.product,
    required this.onAdjust,
    required this.onViewLogs,
  });

  @override
  Widget build(BuildContext context) {
    final stockPercentage = product.minimumStock > 0
        ? (product.currentStock / product.minimumStock * 100).clamp(0, 100)
        : 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.currentStock == 0
              ? AppColors.error
              : product.isLowStock
                  ? AppColors.warning
                  : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildStockIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.storeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (product.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: stockPercentage / 100,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStockColor(),
                            ),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product.currentStock} ${product.unit} / Min: ${product.minimumStock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Purchase Price',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                              .format(product.purchasePrice),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Last Restocked',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(product.lastRestocked),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: onAdjust,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Adjust'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onViewLogs,
                icon: const Icon(Icons.history, size: 16),
                label: const Text('Logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getStockColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            product.currentStock == 0
                ? Icons.remove_circle_outline
                : product.isLowStock
                    ? Icons.warning_amber
                    : Icons.check_circle_outline,
            color: _getStockColor(),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '${product.currentStock}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getStockColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    String status;
    Color color;

    if (product.currentStock == 0) {
      status = 'Out of Stock';
      color = AppColors.error;
    } else if (product.isLowStock) {
      status = 'Low Stock';
      color = AppColors.warning;
    } else {
      status = 'In Stock';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getStockColor() {
    if (product.currentStock == 0) return AppColors.error;
    if (product.isLowStock) return AppColors.warning;
    return AppColors.success;
  }
}