// lib/core/services/api/misc_api_services.dart

import 'package:rs2_desktop/core/api/api_client.dart';
import 'package:rs2_desktop/models/procurement/procurement_order_model.dart';
import 'package:rs2_desktop/models/products/product_model.dart';

// ==================== NOTIFICATIONS API SERVICE ====================

class NotificationsApiService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications({
    bool? isRead,
    String? type,
  }) async {
    return await _client.get(
      '/notifications',
      queryParameters: {
        if (isRead != null) 'isRead': isRead,
        if (type != null) 'type': type,
      },
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['count'] as int);
    }

    return ApiResponse.failure(response.error ?? 'Failed to get unread count');
  }

  Future<ApiResponse<void>> markAsRead(String notificationId) async {
    return await _client.put('/notifications/$notificationId/read');
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    return await _client.put('/notifications/mark-all-read');
  }

  Future<ApiResponse<void>> deleteNotification(String notificationId) async {
    return await _client.delete('/notifications/$notificationId');
  }

  Future<ApiResponse<void>> deleteAllRead() async {
    return await _client.delete('/notifications/delete-all-read');
  }
}

// ==================== RECOMMENDATIONS API SERVICE ====================

class RecommendationsApiService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<ProductModel>>> getRecommendedProducts({
    String? userId,
    int count = 5,
  }) async {
    return await _client.get(
      '/recommendations',
      queryParameters: {
        if (userId != null) 'userId': userId,
        'count': count,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<List<ProductModel>>> getPopularProducts({
    int count = 10,
  }) async {
    return await _client.get(
      '/recommendations/popular',
      queryParameters: {'count': count},
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<List<ProductModel>>> getTimeBasedRecommendations({
    required int hour,
    int count = 5,
  }) async {
    return await _client.get(
      '/recommendations/time-based',
      queryParameters: {
        'hour': hour,
        'count': count,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }
}

// ==================== RECEIPTS API SERVICE ====================

class ReceiptsApiService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> getReceiptByOrderId(String orderId) async {
    return await _client.get(
      '/receipts/order/$orderId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getReceiptById(String receiptId) async {
    return await _client.get(
      '/receipts/$receiptId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getReceipts({
    DateTime? fromDate,
    DateTime? toDate,
    String? paymentMethod,
  }) async {
    return await _client.get(
      '/receipts',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }
}

// ==================== PROCUREMENT API SERVICE ====================

class ProcurementApiService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<List<ProcurementOrderModel>>> getProcurementOrders({
    String? storeId,
  }) async {
    return await _client.get(
      '/procurement',
      queryParameters: {
        if (storeId != null) 'storeId': storeId,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProcurementOrderModel.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<ProcurementOrderModel>> getProcurementOrderById(String id) async {
    return await _client.get(
      '/procurement/$id',
      fromJson: (json) => ProcurementOrderModel.fromJson(json),
    );
  }

  Future<ApiResponse<ProcurementOrderModel>> createProcurementOrder({
    required String storeId,
    required String supplier,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    return await _client.post(
      '/procurement',
      data: {
        'storeId': storeId,
        'supplier': supplier,
        'notes': notes,
        'items': items,
      },
      fromJson: (json) => ProcurementOrderModel.fromJson(json),
    );
  }

  /// ✅ NEW: Create Stripe Checkout Session
  /// Returns: { checkoutUrl: "https://checkout.stripe.com/..." }
  Future<ApiResponse<String>> createCheckoutSession(String procurementOrderId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/procurement/$procurementOrderId/create-checkout-session',
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final checkoutUrl = response.data!['checkoutUrl'] as String;
      return ApiResponse.success(checkoutUrl);
    }

    return ApiResponse.failure(response.error ?? 'Failed to create checkout session');
  }

  Future<ApiResponse<void>> updateProcurementStatus({
    required String procurementOrderId,
    required String status,
  }) async {
    return await _client.put(
      '/procurement/$procurementOrderId/status',
      queryParameters: {'status': status},
    );
  }

  Future<ApiResponse<void>> receiveProcurement({
    required String procurementOrderId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    return await _client.post(
      '/procurement/$procurementOrderId/receive',
      data: {
        'items': items,
        'notes': notes,
      },
    );
  }
}

// ==================== PAYMENTS API SERVICE (STRIPE) ====================

class PaymentsApiService {
  final ApiClient _client = ApiClient();

  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
    String? tableNumber,
    String? customerEmail,
  }) async {
    return await _client.post(
      '/payments/create-intent',
      data: {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
        'tableNumber': tableNumber,
        'customerEmail': customerEmail,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getPaymentIntent(String paymentIntentId) async {
    return await _client.get(
      '/payments/intent/$paymentIntentId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<bool>> confirmPayment(String paymentIntentId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/confirm/$paymentIntentId',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['confirmed'] as bool? ?? false);
    }

    return ApiResponse.failure(response.error ?? 'Payment confirmation failed');
  }

  Future<ApiResponse<bool>> cancelPaymentIntent(String paymentIntentId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/cancel/$paymentIntentId',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['cancelled'] as bool? ?? false);
    }

    return ApiResponse.failure(response.error ?? 'Payment cancellation failed');
  }

  Future<ApiResponse<Map<String, dynamic>>> createRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
  }) async {
    return await _client.post(
      '/payments/refund',
      data: {
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'reason': reason,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getRefund(String refundId) async {
    return await _client.get(
      '/payments/refund/$refundId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}