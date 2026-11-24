/// Resilient HTTP wrapper.
/// Handles GZIP responses, strict timeouts, Supabase bearer auth, retries,
/// and idempotency keys. Bearer auth comes from the signed-in Supabase session; no fake attestation.

library network_client;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/api_config.dart';

/// Standardized error codes for network failures.
enum NetworkErrorCode {
  timeout,
  connectionFailed,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  rateLimited,
  invalidResponse,
  cancelled,
  unknown,
}

/// Result wrapper for network calls.
class NetworkResult<T> {
  const NetworkResult.success(this.data) : error = null;
  const NetworkResult.failure(this.error) : data = null;

  final T? data;
  final NetworkError? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// Structured network error.
class NetworkError {
  const NetworkError(this.code, this.message, {this.statusCode, this.originalError});

  final NetworkErrorCode code;
  final String message;
  final int? statusCode;
  final Object? originalError;

  @override
  String toString() => 'NetworkError($code): $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Configuration for a single request.
class RequestConfig {
  const RequestConfig({
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.idempotencyKey,
    this.requireAuth = true,
  });

  final Duration timeout;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxDelay;
  final String? idempotencyKey;
  final bool requireAuth;
}

/// Resilient HTTP client with Supabase auth, retries, and idempotency.
class NetworkClient {
  NetworkClient({
    http.Client? httpClient,
    sb.SupabaseClient? client,
  })  : _httpClient = httpClient ?? http.Client(),
        _client = client;

  final http.Client _httpClient;
  sb.SupabaseClient? _client;

  /// Resolves Supabase lazily: desktop and test runs can build the client
  /// before Supabase is initialized without crashing.
  sb.SupabaseClient? get _supabase {
    if (_client != null) return _client;
    try {
      _client = sb.Supabase.instance.client;
    } catch (_) {
      _client = null;
    }
    return _client;
  }

  static const Map<int, NetworkErrorCode> _statusCodeMap = {
    400: NetworkErrorCode.invalidResponse,
    401: NetworkErrorCode.unauthorized,
    403: NetworkErrorCode.forbidden,
    404: NetworkErrorCode.notFound,
    408: NetworkErrorCode.timeout,
    429: NetworkErrorCode.rateLimited,
    500: NetworkErrorCode.serverError,
    502: NetworkErrorCode.serverError,
    503: NetworkErrorCode.serverError,
    504: NetworkErrorCode.timeout,
  };

  /// Base URL for API calls (platform-aware, override with
  /// `--dart-define=KASHKOOL_API_BASE=...`)
  static String get defaultBaseUrl => ApiConfig.baseUrl;

  /// GET request with full resilience.
  Future<NetworkResult<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? headers,
    RequestConfig? config,
  }) async {
    final requestHeaders = await _buildHeaders(headers, config);
    return _request(
      () => _httpClient.get(Uri.parse(url), headers: requestHeaders),
      config ?? const RequestConfig(),
    );
  }

  /// POST request with full resilience.
  Future<NetworkResult<Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    RequestConfig? config,
  }) async {
    final requestHeaders = await _buildHeaders(headers, config);
    return _request(
      () => _httpClient.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
      config ?? const RequestConfig(),
    );
  }

  /// PUT request with full resilience.
  Future<NetworkResult<Map<String, dynamic>>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    RequestConfig? config,
  }) async {
    final requestHeaders = await _buildHeaders(headers, config);
    return _request(
      () => _httpClient.put(
        Uri.parse(url),
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
      config ?? const RequestConfig(),
    );
  }

  /// DELETE request with full resilience.
  Future<NetworkResult<Map<String, dynamic>>> delete(
    String url, {
    Map<String, String>? headers,
    RequestConfig? config,
  }) async {
    final requestHeaders = await _buildHeaders(headers, config);
    return _request(
      () => _httpClient.delete(Uri.parse(url), headers: requestHeaders),
      config ?? const RequestConfig(),
    );
  }

  /// Core request execution with retries, timeout, and error mapping.
  Future<NetworkResult<Map<String, dynamic>>> _request(
    Future<http.Response> Function() requestFn,
    RequestConfig config,
  ) async {
    var attempt = 0;
    var delay = config.baseDelay;

    while (true) {
      try {
        final response = await requestFn().timeout(config.timeout);
        return _handleResponse(response);
      } on TimeoutException {
        if (attempt >= config.maxRetries) {
          return NetworkResult.failure(
            NetworkError(NetworkErrorCode.timeout, 'Request timed out after ${config.maxRetries} retries'),
          );
        }
      } on http.ClientException catch (e) {
        if (attempt >= config.maxRetries) {
          return NetworkResult.failure(
            NetworkError(NetworkErrorCode.connectionFailed, 'Connection failed: $e', originalError: e),
          );
        }
      } catch (e) {
        if (attempt >= config.maxRetries) {
          return NetworkResult.failure(
            NetworkError(NetworkErrorCode.unknown, 'Unexpected error: $e', originalError: e),
          );
        }
      }

      attempt++;
      await Future.delayed(delay);
      delay = Duration(milliseconds: ((delay.inMilliseconds * 1.5).round()).clamp(0, config.maxDelay.inMilliseconds));
    }
  }

  /// Build headers with the Supabase access token, gateway key and idempotency key.
  Future<Map<String, String>> _buildHeaders(Map<String, String>? baseHeaders, RequestConfig? config) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?baseHeaders,
    };

    // Authenticates LAN requests to the development gateway. Empty unless the
    // build was configured with --dart-define=KASHKOOL_GATEWAY_KEY.
    if (ApiConfig.gatewayKey.isNotEmpty) {
      headers['x-api-key'] = ApiConfig.gatewayKey;
    }

    if (config?.requireAuth ?? true) {
      final session = _supabase?.auth.currentSession;
      if (session != null) {
        headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
    }

    if (config?.idempotencyKey != null) {
      headers['Idempotency-Key'] = config!.idempotencyKey!;
    }

    return headers;
  }

  /// Map HTTP response to NetworkResult.
  NetworkResult<Map<String, dynamic>> _handleResponse(http.Response response) {
    final errorCode = _statusCodeMap[response.statusCode] ?? NetworkErrorCode.unknown;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return NetworkResult.success(data);
      } catch (e) {
        return NetworkResult.failure(
          NetworkError(NetworkErrorCode.invalidResponse, 'Failed to parse JSON: $e', statusCode: response.statusCode, originalError: e),
        );
      }
    }

    String message = 'HTTP ${response.statusCode}';
    try {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      message = errorData['message'] as String? ?? errorData['error'] as String? ?? message;
    } catch (_) {
      // Use default message
    }

    return NetworkResult.failure(
      NetworkError(errorCode, message, statusCode: response.statusCode),
    );
  }

  void close() {
    _httpClient.close();
  }
}

/// Global provider for the network client.
final networkClientProvider = Provider<NetworkClient>((ref) {
  final client = NetworkClient();
  ref.onDispose(client.close);
  return client;
});
