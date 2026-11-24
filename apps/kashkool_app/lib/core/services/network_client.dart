/// Billing Network Client - minimal HTTP client wrapper for billing/api calls.
/// Path-based (baseUrl prefixed internally), distinct from core/network/NetworkClient.

library billing_network_client;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

class BillingNetworkClient {
  final http.Client _client;
  final String baseUrl;

  /// [baseUrl] defaults to the platform-aware gateway address. Passing an
  /// empty string here used to build relative URIs (`/health`), which made
  /// every request throw `No host specified in URI`.
  BillingNetworkClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? ApiConfig.baseUrl
            : baseUrl;

  Future<BillingNetworkResponse> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.get(uri, headers: _headers);
    return BillingNetworkResponse(
      statusCode: response.statusCode,
      data: _decodeBody(response.body),
    );
  }

  Future<BillingNetworkResponse> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return BillingNetworkResponse(
      statusCode: response.statusCode,
      data: _decodeBody(response.body),
    );
  }

  Future<BillingNetworkResponse> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.put(
      uri,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return BillingNetworkResponse(
      statusCode: response.statusCode,
      data: _decodeBody(response.body),
    );
  }

  /// Gateway key for non-loopback requests; empty when not configured.
  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        if (ApiConfig.gatewayKey.isNotEmpty)
          'x-api-key': ApiConfig.gatewayKey,
      };

  dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  void close() => _client.close();
}

class BillingNetworkResponse {
  final int statusCode;
  final dynamic data;

  BillingNetworkResponse({required this.statusCode, required this.data});
}

/// Provider for the billing network client.
final billingNetworkClientProvider = Provider<BillingNetworkClient>((ref) {
  final client = BillingNetworkClient();
  ref.onDispose(client.close);
  return client;
});
