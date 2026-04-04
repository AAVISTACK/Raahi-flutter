// ============================================================
// lib/services/api_service.dart  — Refactored v2
// Fix: All API errors now throw ApiException (never swallowed)
// Fix: baseUrl reads from environment, not hardcoded constants
// Fix: clearToken() added for sign-out
// ============================================================

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── ApiException — strongly typed error surface ───────────────
// UI catches this instead of seeing silent loading spinners

class ApiException implements Exception {
  final int? statusCode;
  final String? errorCode;    // e.g. "SUBSCRIPTION_EXPIRED"
  final String? message;
  final bool isNetworkError;

  const ApiException({
    this.statusCode,
    this.errorCode,
    this.message,
    this.isNetworkError = false,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isPaymentRequired => statusCode == 402;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() =>
      'ApiException($statusCode, $errorCode): $message';
}

// ── ApiService ────────────────────────────────────────────────

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _authToken;

  // Read from dart-define or fall back to local emulator address
  // Usage: flutter run --dart-define=BASE_URL=https://api.raahi.in/api/v1
  static const _defaultBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1', // Android emulator → localhost
  );

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'x-app-version': '1.0.0',
        if (Platform.isAndroid) 'x-platform': 'android',
        if (Platform.isIOS) 'x-platform': 'ios',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Convert ALL Dio errors to ApiException
          // This is the fix for silent infinite spinners
          throw _mapError(error);
        },
      ),
    );
  }

  // ── Token Management ──────────────────────────────────────

  Future<void> setToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ── Generic Request Methods ───────────────────────────────
  // These throw ApiException — callers don't need try/catch for DioException

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? query}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> data) async {
    final res =
        await _dio.post<Map<String, dynamic>>(path, data: data);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> data) async {
    final res =
        await _dio.put<Map<String, dynamic>>(path, data: data);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> data) async {
    final res =
        await _dio.patch<Map<String, dynamic>>(path, data: data);
    return res.data ?? {};
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }

  // ── Error Mapper ──────────────────────────────────────────

  ApiException _mapError(DioException error) {
    // Network layer errors (no internet, DNS fail, refused connection)
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        isNetworkError: true,
        message:
            'No internet connection or server is unreachable. '
            'Check your network and try again.',
      );
    }

    final response = error.response;
    if (response == null) {
      return ApiException(
        isNetworkError: true,
        message: error.message ?? 'Network error',
      );
    }

    // Server returned an error response — extract structured error body
    final data = response.data;
    final errorCode = data is Map ? data['error'] as String? : null;
    final message = data is Map ? data['message'] as String? : null;

    return ApiException(
      statusCode: response.statusCode,
      errorCode: errorCode,
      message: message ?? _httpStatusMessage(response.statusCode),
    );
  }

  String _httpStatusMessage(int? code) {
    switch (code) {
      case 400: return 'Bad request. Please check your input.';
      case 401: return 'Session expired. Please log in again.';
      case 402: return 'Subscription required.';
      case 403: return 'You don\'t have permission to do this.';
      case 404: return 'Resource not found.';
      case 429: return 'Too many requests. Please slow down.';
      case 500: return 'Server error. Please try again later.';
      case 502: return 'Service temporarily unavailable.';
      case 503: return 'Service is busy. Please try again.';
      default:  return 'Unexpected error (HTTP $code).';
    }
  }

  // ── Admin helpers ──────────────────────────────────────────

  Future<Map<String, dynamic>> getWithAdminSecret(
      String path, String secret) async {
    final res = await _dio.get<Map<String, dynamic>>(
      path,
      options: Options(headers: {'x-admin-secret': secret}),
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> putWithAdminSecret(
      String path, String secret, Map<String, dynamic> data) async {
    final res = await _dio.put<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(headers: {'x-admin-secret': secret}),
    );
    return res.data ?? {};
  }
}
