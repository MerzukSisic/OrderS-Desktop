// lib/features/admin/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/dashboard/widget/revenue_chart_widget.dart';
import 'package:rs2_desktop/features/admin/dashboard/widget/stat_card.dart';
import 'package:rs2_desktop/providers/business_providers.dart';
import 'package:rs2_desktop/providers/notifications_recommendations_providers.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  Future<void> _loadAllData() async {
    final provider = context.read<StatisticsProvider>();

    await Future.wait([
      provider.fetchDashboardStats(),
      provider.fetchTopProducts(count: 5, days: 30),
      provider.fetchPeakHours(days: 7),
      provider.fetchCategorySales(
        fromDate: DateTime.now().subtract(const Duration(days: 30)),
        toDate: DateTime.now(),
      ),
      provider.fetchRevenueChart(
        fromDate: DateTime.now().subtract(const Duration(days: 30)),
        toDate: DateTime.now(),
      ),
      context.read<RecommendationsProvider>().fetchAll(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StatisticsProvider, RecommendationsProvider>(
      builder: (context, provider, recProvider, child) {
        if (provider.isLoading && provider.dashboardStats == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null && provider.dashboardStats == null) {
          return _buildError(provider.error!);
        }
        return _buildContent(provider, recProvider);
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
            onPressed: _loadAllData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StatisticsProvider provider, RecommendationsProvider recProvider) {
    final stats = provider.dashboardStats;
    if (stats == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(stats),
            const SizedBox(height: 24),
            if (provider.revenueChart != null)
              _buildRevenueChart(provider.revenueChart!),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTopProducts(provider.topProducts),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildCategorySales(provider.categorySales),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPeakHours(provider.peakHours),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recProvider.popularProducts.isNotEmpty)
                  Expanded(child: _buildRecommendationSection(
                    title: 'Popular Products',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                    products: recProvider.popularProducts,
                  )),
                if (recProvider.popularProducts.isNotEmpty && recProvider.timeBasedProducts.isNotEmpty)
                  const SizedBox(width: 24),
                if (recProvider.timeBasedProducts.isNotEmpty)
                  Expanded(child: _buildRecommendationSection(
                    title: 'Good Right Now',
                    icon: Icons.access_time,
                    color: Colors.teal,
                    products: recProvider.timeBasedProducts,
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<dynamic> products,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...products.take(5).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.restaurant_menu, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      Text(
                        NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(p.price),
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back! Here\'s what\'s happening today.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(stats) {
    final avgOrderValue = stats.todayOrders > 0 
        ? stats.todayRevenue / stats.todayOrders 
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Today\'s Revenue',
            value: NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                .format(stats.todayRevenue),
            icon: Icons.attach_money,
            color: Colors.green,
            trend: '${stats.todayVsYesterday >= 0 ? '+' : ''}${stats.todayVsYesterday.toStringAsFixed(1)}%',
            isPositiveTrend: stats.todayVsYesterday >= 0,
            subtitle: 'vs yesterday',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Orders Today',
            value: stats.todayOrders.toString(),
            icon: Icons.shopping_cart,
            color: Colors.blue,
            subtitle: 'Week: ${NumberFormat.currency(symbol: 'KM ', decimalDigits: 0).format(stats.weekRevenue)}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Active Tables',
            value: stats.activeTables.toString(),
            icon: Icons.table_restaurant,
            color: Colors.orange,
            subtitle: 'currently occupied',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Avg. Order Value',
            value: NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                .format(avgOrderValue),
            icon: Icons.trending_up,
            color: Colors.purple,
            subtitle: 'Month: ${NumberFormat.currency(symbol: 'KM ', decimalDigits: 0).format(stats.monthRevenue)}',
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(revenueChart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Overview (Last 30 Days)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Total: ${NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(revenueChart.totalRevenue)} • ${revenueChart.totalOrders} orders',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (revenueChart.data.isEmpty)
            _buildEmptyChart()
          else
            RevenueChartWidget(data: revenueChart.data),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No revenue data available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(List products) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No product data available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getProductColor(index).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: _getProductColor(index),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${product.quantitySold} sold',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                          .format(product.revenue),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategorySales(List categories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.pie_chart, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No category data available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            category.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                              .format(category.revenue),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: category.percentage / 100,
                        backgroundColor: AppColors.border,
                        minHeight: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(category.categoryName),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.percentage.toStringAsFixed(1)}% of total sales • ${category.orderCount} orders',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPeakHours(List hours) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peak Hours',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (hours.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No peak hour data available',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hours.length,
                itemBuilder: (context, index) {
                  final hour = hours[index];
                  final maxOrders = hours
                      .map((h) => h.orderCount)
                      .reduce((a, b) => a > b ? a : b);
                  final heightPercent = maxOrders > 0 
                      ? hour.orderCount / maxOrders 
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          hour.orderCount.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 70.0 * heightPercent,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hour.hour}h',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Color _getProductColor(int index) {
    final colors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  Color _getCategoryColor(String categoryName) {
    final hash = categoryName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[hash.abs() % colors.length];
  }
}