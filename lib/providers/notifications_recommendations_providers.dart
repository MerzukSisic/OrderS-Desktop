import 'package:flutter/foundation.dart';
import 'package:rs2_desktop/core/services/api/misc_api_services.dart';
import 'package:rs2_desktop/models/products/product_model.dart';

// ==================== NOTIFICATIONS PROVIDER ====================

class NotificationsProvider with ChangeNotifier {
  final NotificationsApiService _apiService = NotificationsApiService();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getNotifications();
      if (response.success && response.data != null) {
        _notifications = response.data!;
        await _fetchUnreadCount();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();
      if (response.success && response.data != null) {
        _unreadCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> fetchUnreadCount() => _fetchUnreadCount();

  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.markAsRead(notificationId);
      if (response.success) {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, 999);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
    return false;
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.markAllAsRead();
      if (response.success) {
        await fetchNotifications();
        return true;
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
    return false;
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.deleteNotification(notificationId);
      if (response.success) {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
    return false;
  }

  Future<bool> deleteAllRead() async {
    try {
      final response = await _apiService.deleteAllRead();
      if (response.success) {
        await fetchNotifications();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
    }
    return false;
  }
}

// ==================== RECOMMENDATIONS PROVIDER ====================

class RecommendationsProvider with ChangeNotifier {
  final RecommendationsApiService _apiService = RecommendationsApiService();

  List<ProductModel> _popularProducts = [];
  List<ProductModel> _timeBasedProducts = [];
  bool _isLoading = false;

  List<ProductModel> get popularProducts => _popularProducts;
  List<ProductModel> get timeBasedProducts => _timeBasedProducts;
  bool get isLoading => _isLoading;

  Future<void> fetchPopularProducts({int count = 5}) async {
    try {
      final response = await _apiService.getPopularProducts(count: count);
      if (response.success && response.data != null) {
        _popularProducts = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching popular products: $e');
    }
  }

  Future<void> fetchTimeBasedRecommendations({int count = 5}) async {
    try {
      final response = await _apiService.getTimeBasedRecommendations(
        hour: DateTime.now().hour,
        count: count,
      );
      if (response.success && response.data != null) {
        _timeBasedProducts = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching time-based recommendations: $e');
    }
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      fetchPopularProducts(),
      fetchTimeBasedRecommendations(),
    ]);
    _isLoading = false;
    notifyListeners();
  }
}
