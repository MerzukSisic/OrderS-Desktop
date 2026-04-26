import 'package:flutter/foundation.dart';
import 'package:rs2_desktop/core/errors/ui_error_mapper.dart';
import 'package:rs2_desktop/core/services/api/misc_api_services.dart';
import 'package:rs2_desktop/models/procurement/procurement_order_model.dart';

class PaymentInitiationResult {
  final bool success;
  final String userMessage;
  final String? checkoutUrl;

  const PaymentInitiationResult({
    required this.success,
    required this.userMessage,
    this.checkoutUrl,
  });
}

// ==================== PROCUREMENT PROVIDER ====================

class ProcurementProvider with ChangeNotifier {
  final ProcurementApiService _apiService;

  ProcurementProvider({ProcurementApiService? apiService})
    : _apiService = apiService ?? ProcurementApiService();

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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to load procurement orders right now.',
        ).userMessage,
      );
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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to load this order right now.',
        ).userMessage,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createProcurementOrder({
    required String storeId,
    String? sourceStoreId,
    required String supplier,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createProcurementOrder(
        storeId: storeId,
        sourceStoreId: sourceStoreId,
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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to create the order right now.',
        ).userMessage,
      );
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a Stripe Checkout session and returns URL + user-safe message.
  Future<PaymentInitiationResult> initiatePayment(
    String procurementOrderId,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔵 Creating checkout session for order: $procurementOrderId');

      final response = await _apiService.createCheckoutSession(
        procurementOrderId,
      );

      if (response.success && response.data != null) {
        return PaymentInitiationResult(
          success: true,
          checkoutUrl: response.data!,
          userMessage: 'Checkout is ready.',
        );
      }

      final message = UiErrorMapper.userMessageFromRaw(
        response.error,
        fallback: 'Unable to start checkout right now.',
      );
      _setError(message);
      debugPrint('❌ Checkout Session Error: ${response.error}');
      return PaymentInitiationResult(success: false, userMessage: message);
    } catch (e) {
      final message = UiErrorMapper.fromException(
        e,
        fallback: 'Unable to start checkout right now.',
      ).userMessage;
      _setError(message);
      debugPrint('❌ Payment Initiation Error: $e');
      return PaymentInitiationResult(success: false, userMessage: message);
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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to update order status right now.',
        ).userMessage,
      );
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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to mark this order as received right now.',
        ).userMessage,
      );
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
  final PaymentsApiService _apiService;

  PaymentsProvider({PaymentsApiService? apiService})
    : _apiService = apiService ?? PaymentsApiService();

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
        if (kDebugMode) {
          debugPrint('Payment intent created');
        }
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to create payment intent');
        return null;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to create payment intent right now.',
        ).userMessage,
      );
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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to load payment intent right now.',
        ).userMessage,
      );
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
        if (kDebugMode) {
          debugPrint('Payment confirmed');
        }
        return true;
      } else {
        _setError(response.error ?? 'Payment confirmation failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to confirm payment right now.',
        ).userMessage,
      );
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
        if (kDebugMode) {
          debugPrint('Payment intent cancelled');
        }
        return true;
      } else {
        _setError(response.error ?? 'Payment cancellation failed');
        return false;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to cancel payment right now.',
        ).userMessage,
      );
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
        if (kDebugMode) {
          debugPrint('Refund created');
        }
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to create refund');
        return null;
      }
    } catch (e) {
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to create refund right now.',
        ).userMessage,
      );
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
      _setError(
        UiErrorMapper.fromException(
          e,
          fallback: 'Unable to load refund details right now.',
        ).userMessage,
      );
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
