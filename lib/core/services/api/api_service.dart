import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;  
import 'package:shared_preferences/shared_preferences.dart'; // ✅ PROMIJENJENO
import 'package:rs2_desktop/core/constants/api_constants.dart';
import 'package:rs2_desktop/models/products/accompaniment.dart';
import 'package:rs2_desktop/models/products/accompaniment_group.dart';

import '../../constants/app_constants.dart';

class ApiService {
  static const bool _logHttp = true;

  void _log(String message) {
    if (_logHttp && kDebugMode) {
      debugPrint(message);
    }
  }

  String _extractServerMessage(http.Response response) {
    final body = response.body;
    if (body.isEmpty) return 'HTTP ${response.statusCode}';

    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        final msg = decoded['message'] ?? decoded['error'];
        if (msg != null) return msg.toString();

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstKey = errors.keys.first;
          final val = errors[firstKey];
          if (val is List && val.isNotEmpty) return val.first.toString();
          return val?.toString() ?? 'HTTP ${response.statusCode}';
        }
      }
    } catch (_) {}

    return body.length > 300 ? body.substring(0, 300) : body;
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;

  // ============================================
  // TOKEN MANAGEMENT - USING SHARED PREFERENCES
  // ============================================

  /// Get stored access token
  Future<String?> getToken() async {
    if (_accessToken != null) return _accessToken;
    
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.keyAccessToken);
    return _accessToken;
  }

  /// Save access token
  Future<void> saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, token);
    debugPrint('🔑 Token saved to SharedPreferences');
  }

  /// Clear access token
  Future<void> clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    debugPrint('🗑️ Token cleared from SharedPreferences');
  }

  // ============================================
  // HEADERS
  // ============================================

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // HTTP METHODS
  // ============================================

  /// GET Request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint)
        .replace(queryParameters: queryParams);

    try {
      _log('➡️ GET  $uri');

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(ApiConstants.timeout);

      _log('⬅️ GET  $uri  [${response.statusCode}] ${response.body.isEmpty ? '(empty body)' : ''}');
      return _handleResponse(response, uri: uri);
    } on http.ClientException catch (e) {
      throw ApiException('Connection error: ${e.message}. URL: $uri');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        throw ApiException('Request timeout. URL: $uri');
      }
      throw ApiException('Network error: $errorMessage. URL: $uri');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}. URL: $uri');
    }
  }

  /// POST Request
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

    try {
      _log('➡️ POST $uri');
      _log(body == null ? '   body: null' : '   body: ${json.encode(body)}');

      final response = await http
          .post(uri, headers: await _getHeaders(), body: json.encode(body))
          .timeout(ApiConstants.timeout);

      _log('⬅️ POST $uri  [${response.statusCode}] ${response.body.isEmpty ? '(empty body)' : ''}');
      return _handleResponse(response, uri: uri);
    } on http.ClientException catch (e) {
      throw ApiException('Connection error: ${e.message}. URL: $uri');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        throw ApiException('Request timeout. URL: $uri');
      }
      throw ApiException('Network error: $errorMessage. URL: $uri');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}. URL: $uri');
    }
  }

  /// PUT Request
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

    try {
      _log('➡️ PUT  $uri');
      _log(body == null ? '   body: null' : '   body: ${json.encode(body)}');

      final response = await http
          .put(uri, headers: await _getHeaders(), body: json.encode(body))
          .timeout(ApiConstants.timeout);

      _log('⬅️ PUT  $uri  [${response.statusCode}] ${response.body.isEmpty ? '(empty body)' : ''}');
      return _handleResponse(response, uri: uri);
    } on http.ClientException catch (e) {
      throw ApiException('Connection error: ${e.message}. URL: $uri');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        throw ApiException('Request timeout. URL: $uri');
      }
      throw ApiException('Network error: $errorMessage. URL: $uri');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}. URL: $uri');
    }
  }

  /// PATCH Request
  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

    try {
      _log('➡️ PATCH $uri');
      _log(body == null ? '   body: null' : '   body: ${json.encode(body)}');

      final response = await http
          .patch(uri, headers: await _getHeaders(), body: json.encode(body))
          .timeout(ApiConstants.timeout);

      _log('⬅️ PATCH $uri  [${response.statusCode}] ${response.body.isEmpty ? '(empty body)' : ''}');
      return _handleResponse(response, uri: uri);
    } on http.ClientException catch (e) {
      throw ApiException('Connection error: ${e.message}. URL: $uri');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        throw ApiException('Request timeout. URL: $uri');
      }
      throw ApiException('Network error: $errorMessage. URL: $uri');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}. URL: $uri');
    }
  }

  /// DELETE Request
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse(ApiConstants.baseUrl + endpoint);

    try {
      _log('➡️ DELETE $uri');

      final response = await http
          .delete(uri, headers: await _getHeaders())
          .timeout(ApiConstants.timeout);

      _log('⬅️ DELETE $uri  [${response.statusCode}] ${response.body.isEmpty ? '(empty body)' : ''}');
      return _handleResponse(response, uri: uri);
    } on http.ClientException catch (e) {
      throw ApiException('Connection error: ${e.message}. URL: $uri');
    } on Exception catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        throw ApiException('Request timeout. URL: $uri');
      }
      throw ApiException('Network error: $errorMessage. URL: $uri');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}. URL: $uri');
    }
  }

  // ============================================
  // RESPONSE HANDLER
  // ============================================

  dynamic _handleResponse(http.Response response, {Uri? uri}) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        return json.decode(response.body);

      case 204:
        return null;

      case 400:
        throw ApiException('Bad request (${response.statusCode})${uri != null ? ' for $uri' : ''}: ${_extractServerMessage(response)}');

      case 401:
        throw UnauthorizedException('Unauthorized (${response.statusCode})${uri != null ? ' for $uri' : ''}: ${_extractServerMessage(response)}');

      case 403:
        throw ApiException('Forbidden (${response.statusCode})${uri != null ? ' for $uri' : ''}: ${_extractServerMessage(response)}');

      case 404:
        throw ApiException('Not found (${response.statusCode})${uri != null ? ' for $uri' : ''}: ${_extractServerMessage(response)}');

      case 500:
      default:
        throw ApiException('HTTP ${response.statusCode}${uri != null ? ' for $uri' : ''}: ${_extractServerMessage(response)}');
    }
  }

  // ============================================
  // ACCOMPANIMENTS API (ostalo nepromijenjeno)
  // ============================================

  Future<List<AccompanimentGroup>> getProductAccompaniments(String productId) async {
    final response = await get('/accompaniments/product/$productId');
    if (response == null) return [];
    final List<dynamic> list = response as List;
    return list.map((json) => AccompanimentGroup.fromJson(json)).toList();
  }

  Future<AccompanimentGroup> getAccompanimentGroup(String groupId) async {
    final response = await get('/accompaniments/groups/$groupId');
    return AccompanimentGroup.fromJson(response);
  }

  Future<AccompanimentGroup> createAccompanimentGroup(Map<String, dynamic> data) async {
    final response = await post('/accompaniments/groups', body: data);
    return AccompanimentGroup.fromJson(response);
  }

  Future<void> updateAccompanimentGroup(String groupId, Map<String, dynamic> data) async {
    await put('/accompaniments/groups/$groupId', body: data);
  }

  Future<void> deleteAccompanimentGroup(String groupId) async {
    await delete('/accompaniments/groups/$groupId');
  }

  Future<Accompaniment> addAccompaniment(String groupId, Map<String, dynamic> data) async {
    final response = await post('/accompaniments/groups/$groupId/accompaniments', body: data);
    return Accompaniment.fromJson(response);
  }

  Future<Accompaniment> getAccompaniment(String accompanimentId) async {
    final response = await get('/accompaniments/$accompanimentId');
    return Accompaniment.fromJson(response);
  }

  Future<void> updateAccompaniment(String accompanimentId, Map<String, dynamic> data) async {
    await put('/accompaniments/$accompanimentId', body: data);
  }

  Future<void> deleteAccompaniment(String accompanimentId) async {
    await delete('/accompaniments/$accompanimentId');
  }

  Future<bool> toggleAccompanimentAvailability(String accompanimentId) async {
    final response = await patch('/accompaniments/$accompanimentId/toggle-availability', body: {});
    return response['isAvailable'] as bool;
  }

  Future<Map<String, dynamic>> validateAccompanimentSelection(
    String productId,
    List<String> selectedAccompanimentIds,
  ) async {
    final response = await post('/accompaniments/validate', body: {
      'productId': productId,
      'selectedAccompanimentIds': selectedAccompanimentIds,
    });
    return response as Map<String, dynamic>;
  }

  Future<double> calculateAccompanimentCharges(List<String> accompanimentIds) async {
    final response = await post('/accompaniments/calculate-charges', body: accompanimentIds);
    return (response['totalExtraCharge'] as num).toDouble();
  }
}

// ============================================
// EXCEPTIONS
// ============================================

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}