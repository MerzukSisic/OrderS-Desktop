// lib/features/admin/procurement/screens/procurement_checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rs2_desktop/core/theme/app_colors.dart';
import 'package:rs2_desktop/features/admin/shared/admin_scaffold.dart';
import 'package:rs2_desktop/providers/procurement_payments_providers.dart';
import 'package:rs2_desktop/providers/auth_provider.dart';
import 'package:rs2_desktop/routes/app_router.dart';
import 'package:intl/intl.dart';

class ProcurementCheckoutScreen extends StatefulWidget {
  final String orderId;

  const ProcurementCheckoutScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ProcurementCheckoutScreen> createState() => _ProcurementCheckoutScreenState();
}

class _ProcurementCheckoutScreenState extends State<ProcurementCheckoutScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  final _dio = Dio();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<ProcurementProvider>().fetchProcurementOrderById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Checkout',
      currentRoute: AppRouter.adminProcurement,
      body: Consumer<ProcurementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.selectedOrder == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.selectedOrder == null) {
            return _buildError(provider.error!);
          }

          if (provider.selectedOrder == null) {
            return _buildNotFound();
          }

          return _buildContent(provider.selectedOrder!);
        },
      ),
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

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Order not found',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic order) {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildCurrentStep(order),
          ),
        ),
        _buildBottomActions(order),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _buildStepItem(0, 'Review Order', Icons.preview),
          _buildStepConnector(0),
          _buildStepItem(1, 'Payment', Icons.payment),
          _buildStepConnector(1),
          _buildStepItem(2, 'Confirmation', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? AppColors.success : AppColors.border,
      ),
    );
  }

  Widget _buildCurrentStep(dynamic order) {
    switch (_currentStep) {
      case 0:
        return _buildOrderReviewStep(order);
      case 1:
        return _buildPaymentStep(order);
      case 2:
        return _buildConfirmationStep(order);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Order Review
  Widget _buildOrderReviewStep(dynamic order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Order',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review your order details before proceeding to payment',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildOrderInfoCard(order),
                  const SizedBox(height: 24),
                  _buildItemsListCard(order),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildOrderSummaryCard(order),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderInfoCard(dynamic order) {
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
            'Order Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Order ID', order.id.substring(0, 8).toUpperCase()),
          const SizedBox(height: 12),
          _buildInfoRow('Store', order.storeName),
          const SizedBox(height: 12),
          _buildInfoRow('Supplier', order.supplier),
          const SizedBox(height: 12),
          _buildInfoRow('Order Date', DateFormat('MMM dd, yyyy').format(order.orderDate)),
          if (order.notes != null && order.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Notes', order.notes),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsListCard(dynamic order) {
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
            'Order Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.storeProductName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quantity: ${item.quantity}',
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
                          .format(item.subtotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(dynamic order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', order.totalAmount),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                    .format(order.totalAmount),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // STEP 2: Payment (Stripe Checkout)
  Widget _buildPaymentStep(dynamic order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Click "Pay with Stripe" to complete your payment securely',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        
        // Stripe Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            border: Border.all(color: AppColors.info),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.info, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secure Payment with Stripe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You will be redirected to Stripe\'s secure payment page',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              // Test Cards Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Stripe Test Cards',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTestCardRow('✅ Success', '4242 4242 4242 4242'),
                  _buildTestCardRow('❌ Decline', '4000 0000 0000 0002'),
                  _buildTestCardRow('⚠️ Insufficient Funds', '4000 0000 0000 9995'),
                  const SizedBox(height: 8),
                  Text(
                    'Use any future date (e.g., 12/34) and any 3-digit CVV',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Order Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Subtotal', order.totalAmount),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    NumberFormat.currency(symbol: 'KM ', decimalDigits: 2)
                        .format(order.totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestCardRow(String label, String cardNumber) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            cardNumber,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Confirmation
  Widget _buildConfirmationStep(dynamic order) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your procurement order has been paid successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildConfirmationRow('Order ID', order.id.substring(0, 8).toUpperCase()),
                  const SizedBox(height: 12),
                  _buildConfirmationRow('Supplier', order.supplier),
                  const SizedBox(height: 12),
                  _buildConfirmationRow('Amount Paid', 
                    NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(order.totalAmount)),
                  const SizedBox(height: 12),
                  _buildConfirmationRow('Status', 'Paid'),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRouter.adminProcurement,
                    ),
                    icon: const Icon(Icons.list),
                    label: const Text('View All Orders'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.adminDashboard,
                      (route) => false,
                    ),
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Go to Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: 'KM ', decimalDigits: 2).format(amount),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(dynamic order) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0 && _currentStep < 2)
            OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () {
                      setState(() {
                        _currentStep--;
                      });
                    },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep < 2)
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _handleNext(order),
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(_currentStep == 1 ? Icons.payment : Icons.arrow_forward),
              label: Text(_currentStep == 1 ? 'Pay with Stripe' : 'Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  // ============ STRIPE CHECKOUT PAYMENT HANDLING ============
  Future<void> _handleNext(dynamic order) async {
    if (_currentStep == 0) {
      // Move to payment step
      setState(() {
        _currentStep = 1;
      });
    } else if (_currentStep == 1) {
      // Process Stripe Checkout payment
      setState(() {
        _isProcessing = true;
      });

      try {
        // ✅ FIXED: Get token properly from AuthProvider
        final authProvider = context.read<AuthProvider>();
        final token = authProvider.token;
        
        if (token == null || token.isEmpty) {
          throw Exception('Authentication token not found. Please login again.');
        }
        
        debugPrint('🔑 Using token: ${token.substring(0, 20)}...');
        
        // Create Stripe Checkout Session
        final response = await _dio.post(
          'http://127.0.0.1:5220/api/procurement/${order.id}/create-checkout-session',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );

        final checkoutUrl = response.data['checkoutUrl'] as String;
        debugPrint('🔗 Stripe Checkout URL: $checkoutUrl');

        // Open Stripe Checkout in browser
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Show polling dialog
          if (!mounted) return;
          _showPollingDialog(order.id);
        } else {
          throw Exception('Could not launch Stripe Checkout');
        }
      } on DioException catch (e) {
        debugPrint('❌ DioException: ${e.message}');
        debugPrint('❌ Response: ${e.response?.data}');
        
        if (!mounted) return;
        
        String errorMessage = 'Failed to open Stripe Checkout';
        if (e.response?.statusCode == 401) {
          errorMessage = 'Session expired. Please login again.';
        } else if (e.response?.data != null) {
          errorMessage = e.response!.data['error']?.toString() ?? errorMessage;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        
        setState(() {
          _isProcessing = false;
        });
      } catch (e) {
        debugPrint('❌ Checkout Error: $e');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Stripe Checkout: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
        
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPollingDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Processing Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Complete payment in the browser window...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Checking payment status...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );

    // Start polling for payment status
    _pollPaymentStatus(orderId);
  }

  Future<void> _pollPaymentStatus(String orderId) async {
    const maxAttempts = 60; // 3 minutes (60 * 3s)
    
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 3));
      
      try {
        await context.read<ProcurementProvider>().fetchProcurementOrderById(orderId);
        final order = context.read<ProcurementProvider>().selectedOrder;
        
        if (order?.status == 'Paid') {
          debugPrint('✅ Payment confirmed! Order status: ${order?.status}');
          
          if (!mounted) return;
          Navigator.of(context).pop(); // Close polling dialog
          
          setState(() {
            _currentStep = 2; // Move to success screen
            _isProcessing = false;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Payment successful!'),
              backgroundColor: AppColors.success,
            ),
          );
          
          return;
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    }
    
    // Timeout - payment verification took too long
    if (!mounted) return;
    Navigator.of(context).pop(); // Close dialog
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment verification timeout. Please check order status manually.'),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 5),
      ),
    );
    
    setState(() {
      _isProcessing = false;
    });
  }
}