import 'package:flutter/foundation.dart';
import 'package:rs2_desktop/core/services/api/misc_api_services.dart';
import 'package:rs2_desktop/models/procurement/procurement_order_model.dart';
import 'package:url_launcher/url_launcher.dart';

// ==================== PROCUREMENT PROVIDER ====================

class ProcurementProvider with ChangeNotifier {
  final ProcurementApiService _apiService = ProcurementApiService();

  // State
  List<ProcurementOrderModel> _procurementOrders = [];
  ProcurementOrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProcurementOrderModel> get procurementOrders => _procurementOrders;
  ProcurementOrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ProcurementOrderModel> get pendingOrders {
    return _procurementOrders.where((o) => o.status == 'Pending').toList();
  }

  List<ProcurementOrderModel> get paidOrders {
    return _procurementOrders.where((o) => o.status == 'Paid').toList();
  }

  List<ProcurementOrderModel> get receivedOrders {
    return _procurementOrders.where((o) => o.status == 'Received').toList();
  }

  Future<void> fetchProcurementOrders({String? storeId}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProcurementOrders(storeId: storeId);

      if (response.success && response.data != null) {
        _procurementOrders = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch procurement orders');
      }
    } catch (e) {
      _setError('Error fetching procurement orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchProcurementOrderById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProcurementOrderById(id);

      if (response.success && response.data != null) {
        _selectedOrder = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch order');
      }
    } catch (e) {
      _setError('Error fetching order: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createProcurementOrder({
    required String storeId,
    required String supplier,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createProcurementOrder(
        storeId: storeId,
        supplier: supplier,
        notes: notes,
        items: items,
      );

      if (response.success && response.data != null) {
        _selectedOrder = response.data;
        await fetchProcurementOrders(storeId: storeId);
        return true;
      } else {
        _setError(response.error ?? 'Failed to create procurement order');
        return false;
      }
    } catch (e) {
      _setError('Error creating procurement order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ NEW: Initiate Stripe Checkout Payment
  /// Opens browser with Stripe Checkout URL
  /// Payment is confirmed automatically via webhook
  Future<bool> initiatePayment(String procurementOrderId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔵 Creating checkout session for order: $procurementOrderId');
      
      final response = await _apiService.createCheckoutSession(procurementOrderId);

      if (response.success && response.data != null) {
        final checkoutUrl = response.data!;
        debugPrint('🔗 Stripe Checkout URL: $checkoutUrl');

        // Open Stripe Checkout in browser
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('✅ Stripe Checkout opened in browser');
          return true;
        } else {
          _setError('Could not open Stripe Checkout');
          debugPrint('❌ Failed to launch URL: $checkoutUrl');
          return false;
        }
      } else {
        _setError(response.error ?? 'Failed to create checkout session');
        debugPrint('❌ Checkout Session Error: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Error initiating payment: $e');
      debugPrint('❌ Payment Initiation Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProcurementStatus({
    required String procurementOrderId,
    required String status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateProcurementStatus(
        procurementOrderId: procurementOrderId,
        status: status,
      );

      if (response.success) {
        await fetchProcurementOrders();
        return true;
      } else {
        _setError(response.error ?? 'Failed to update status');
        return false;
      }
    } catch (e) {
      _setError('Error updating status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> receiveProcurement({
    required String procurementOrderId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.receiveProcurement(
        procurementOrderId: procurementOrderId,
        items: items,
        notes: notes,
      );

      if (response.success) {
        await fetchProcurementOrderById(procurementOrderId);
        return true;
      } else {
        _setError(response.error ?? 'Failed to receive procurement');
        return false;
      }
    } catch (e) {
      _setError('Error receiving procurement: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedOrder(ProcurementOrderModel? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Procurement Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

// ==================== PAYMENTS PROVIDER ====================

class PaymentsProvider with ChangeNotifier {
  final PaymentsApiService _apiService = PaymentsApiService();

  // State
  Map<String, dynamic>? _currentPaymentIntent;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get currentPaymentIntent => _currentPaymentIntent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, dynamic>?> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
    String? tableNumber,
    String? customerEmail,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createPaymentIntent(
        orderId: orderId,
        amount: amount,
        currency: currency,
        tableNumber: tableNumber,
        customerEmail: customerEmail,
      );

      if (response.success && response.data != null) {
        _currentPaymentIntent = response.data;
        debugPrint('✅ Payment Intent Created: ${response.data}');
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to create payment intent');
        return null;
      }
    } catch (e) {
      _setError('Error creating payment intent: $e');
      debugPrint('❌ Payment Intent Error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getPaymentIntent(String paymentIntentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getPaymentIntent(paymentIntentId);

      if (response.success && response.data != null) {
        _currentPaymentIntent = response.data;
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to get payment intent');
        return null;
      }
    } catch (e) {
      _setError('Error getting payment intent: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmPayment(String paymentIntentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.confirmPayment(paymentIntentId);

      if (response.success && response.data == true) {
        debugPrint('✅ Payment Confirmed: $paymentIntentId');
        return true;
      } else {
        _setError(response.error ?? 'Payment confirmation failed');
        return false;
      }
    } catch (e) {
      _setError('Error confirming payment: $e');
      debugPrint('❌ Confirm Payment Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelPaymentIntent(String paymentIntentId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.cancelPaymentIntent(paymentIntentId);

      if (response.success && response.data == true) {
        _currentPaymentIntent = null;
        notifyListeners();
        debugPrint('✅ Payment Intent Cancelled: $paymentIntentId');
        return true;
      } else {
        _setError(response.error ?? 'Payment cancellation failed');
        return false;
      }
    } catch (e) {
      _setError('Error cancelling payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> createRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createRefund(
        paymentIntentId: paymentIntentId,
        amount: amount,
        reason: reason,
      );

      if (response.success && response.data != null) {
        debugPrint('✅ Refund Created: ${response.data}');
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to create refund');
        return null;
      }
    } catch (e) {
      _setError('Error creating refund: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getRefund(String refundId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getRefund(refundId);

      if (response.success && response.data != null) {
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to get refund');
        return null;
      }
    } catch (e) {
      _setError('Error getting refund: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void clearPaymentIntent() {
    _currentPaymentIntent = null;
    notifyListeners();
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Payments Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}