import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rs2_desktop/config/env_config.dart';
import 'package:rs2_desktop/core/errors/ui_error_mapper.dart';

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;
  final int? statusCode;

  ApiResponse({this.data, this.error, required this.success, this.statusCode});

  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse(data: data, success: true, statusCode: statusCode);
  }

  factory ApiResponse.failure(String error, {int? statusCode}) {
    return ApiResponse(error: error, success: false, statusCode: statusCode);
  }
}

/// Base API Client
class ApiClient {
  late final Dio _dio;
  String? _token;
  Future<void> Function()? onUnauthorized;

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  static String _getBaseUrl() {
    return EnvConfig.baseUrl;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          if (kDebugMode) {
            debugPrint('REQUEST[${options.method}] => ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
            );
            debugPrint('Message: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token
  void setToken(String? token) {
    _token = token;
    if (kDebugMode) {
      debugPrint('Token set: ${token != null ? "Yes" : "No"}');
    }
  }

  /// Clear authentication token
  void clearToken() {
    _token = null;
    if (kDebugMode) {
      debugPrint('Token cleared');
    }
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('GET ${_dio.options.baseUrl}$path');
      }
      final response = await _dio.get(path, queryParameters: queryParameters);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = fromJson != null
            ? fromJson(response.data)
            : response.data as T;
        return ApiResponse.success(data, statusCode: response.statusCode);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error: $e');
      }
      return ApiResponse.failure(
        UiErrorMapper.fromException(
          e,
          fallback: 'Something went wrong while loading data.',
        ).userMessage,
      );
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('POST ${_dio.options.baseUrl}$path');
      }
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = fromJson != null
            ? fromJson(response.data)
            : response.data as T;
        return ApiResponse.success(
          responseData,
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 204) {
        return ApiResponse.success(null as T, statusCode: 204);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error: $e');
      }
      return ApiResponse.failure(
        UiErrorMapper.fromException(
          e,
          fallback: 'Something went wrong while sending data.',
        ).userMessage,
      );
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('PUT ${_dio.options.baseUrl}$path');
      }
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 204 || response.data == null) {
          return ApiResponse.success(
            null as T,
            statusCode: response.statusCode,
          );
        }
        final responseData = fromJson != null
            ? fromJson(response.data)
            : response.data as T;
        return ApiResponse.success(
          responseData,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error: $e');
      }
      return ApiResponse.failure(
        UiErrorMapper.fromException(
          e,
          fallback: 'Something went wrong while updating data.',
        ).userMessage,
      );
    }
  }

  /// DELETE request
  Future<ApiResponse<void>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('DELETE ${_dio.options.baseUrl}$path');
      }
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(null, statusCode: response.statusCode);
      }

      return ApiResponse.failure(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error: $e');
      }
      return ApiResponse.failure(
        UiErrorMapper.fromException(
          e,
          fallback: 'Something went wrong while deleting data.',
        ).userMessage,
      );
    }
  }

  /// Handle Dio errors
  ApiResponse<T> _handleDioError<T>(DioException error) {
    String errorMessage;
    int? statusCode = error.response?.statusCode;

    if (kDebugMode) {
      debugPrint('DioException Type: ${error.type}');
      debugPrint('DioException Message: ${error.message}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Request timed out. Please try again.';
        break;

      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          clearToken();
          final callback = onUnauthorized;
          if (callback != null) {
            unawaited(callback());
          }
        }
        errorMessage = UiErrorMapper.userMessageFromRaw(
          _extractErrorMessage(error.response?.data),
          fallback: 'Request failed. Please try again.',
        );
        break;

      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;

      case DioExceptionType.connectionError:
        errorMessage = 'Cannot reach the server right now. Please try again.';
        if (kDebugMode) {
          debugPrint('Backend URL: ${_dio.options.baseUrl}');
        }
        break;

      default:
        errorMessage = UiErrorMapper.userMessageFromRaw(
          error.message,
          fallback: 'An unexpected error occurred. Please try again.',
        );
        if (kDebugMode) {
          debugPrint('Backend URL: ${_dio.options.baseUrl}');
        }
    }

    return ApiResponse.failure(errorMessage, statusCode: statusCode);
  }

  /// Extract error message from response
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first?.toString();
        }
        return firstValue?.toString();
      }

      return data['message'] ??
          data['error'] ??
          data['title'] ??
          data['detail'];
    }

    if (data is String) return data;

    return null;
  }

  /// Get Dio instance (for custom usage)
  Dio get dio => _dio;
}
