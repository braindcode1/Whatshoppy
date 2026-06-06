import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatshoppy2/config/api_config.dart';

class ApiClient {
  static String? _resolvedBaseUrl;

  static const Duration _timeout = Duration(seconds: 20);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// URLs tried only in debug when no production/custom URL works.
  static const List<String> _localDevCandidates = [
    'http://127.0.0.1:3000',
    'http://10.0.2.2:3000',
    'http://localhost:3000',
  ];

  static Future<String> getBaseUrl() async {
    if (_resolvedBaseUrl != null) {
      return _resolvedBaseUrl!;
    }

    final prefs = await SharedPreferences.getInstance();
    final candidates = <String>[];

    final custom = prefs.getString(ApiConfig.customBackendUrlKey);
    if (custom != null && custom.trim().isNotEmpty) {
      candidates.add(_normalizeBaseUrl(custom));
    }

    if (ApiConfig.hasProductionUrl) {
      candidates.add(_normalizeBaseUrl(ApiConfig.productionBaseUrl));
    }

    if (kIsWeb) {
      final webUri = Uri.base;
      final webHost = webUri.host;
      if (webHost.isNotEmpty) {
        candidates.add('http://$webHost:3000');
      }
    }

    if (kDebugMode) {
      candidates.addAll(_localDevCandidates);
    }

    for (final url in candidates) {
      if (await _checkHealth(url)) {
        _resolvedBaseUrl = url;
        if (kDebugMode) {
          debugPrint('[ApiClient] Connected to backend => $url');
        }
        return url;
      }
    }

    if (ApiConfig.hasProductionUrl) {
      throw ApiException(
        'Cannot reach server at ${ApiConfig.productionBaseUrl}.\n'
        'Check that the backend is deployed and online.',
      );
    }

    if (custom != null && custom.trim().isNotEmpty) {
      throw ApiException(
        'Cannot reach server at $custom.\n'
        'Open Settings → Backend server and verify the URL.',
      );
    }

    throw const ApiException(
      'Cannot reach backend.\n\n'
      'For use on any Wi‑Fi or mobile data, build with:\n'
      'flutter run --dart-define=API_BASE_URL=https://your-server.com\n\n'
      'Local dev: start node server.js and use USB adb reverse, emulator, or same Wi‑Fi.',
    );
  }

  static String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static Future<void> setCustomBackendUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    _resolvedBaseUrl = null;

    if (url == null || url.trim().isEmpty) {
      await prefs.remove(ApiConfig.customBackendUrlKey);
      return;
    }

    await prefs.setString(
      ApiConfig.customBackendUrlKey,
      _normalizeBaseUrl(url),
    );
  }

  static Future<String?> getCustomBackendUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.customBackendUrlKey);
  }

  static Future<bool> testBackendUrl(String url) async {
    return _checkHealth(_normalizeBaseUrl(url));
  }

  static void clearResolvedBaseUrl() {
    _resolvedBaseUrl = null;
  }

  static Future<bool> _checkHealth(String url) async {
    try {
      final uri = Uri.parse('$url/health');

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        return decoded['success'] == true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ApiClient] Health check failed => $url');
        debugPrint('[ApiClient] Error => $e');
      }
    }

    return false;
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    final possibleKeys = [
      'user_id',
      'userId',
      'uid',
      'id',
    ];

    for (final key in possibleKeys) {
      final value = prefs.getString(key);

      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final userJson = prefs.getString('user');

    if (userJson != null && userJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson);

        final id = decoded['id']?.toString();

        if (id != null && id.trim().isNotEmpty) {
          return id.trim();
        }
      } catch (_) {}
    }

    final authJson = prefs.getString('auth_user');

    if (authJson != null && authJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(authJson);

        final id = decoded['id']?.toString();

        if (id != null && id.trim().isNotEmpty) {
          return id.trim();
        }
      } catch (_) {}
    }

    throw const ApiException(
      'User not logged in. Please sign in again.',
    );
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final resolvedUrl = await getBaseUrl();

    final uri = _buildUri(
      path,
      queryParams,
      resolvedUrl,
    );

    _log('GET', uri.toString());

    try {
      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(_timeout);

      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _resolvedBaseUrl = null;

      throw ApiException(
        _backendUnavailableMessage(e),
      );
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resolvedUrl = await getBaseUrl();

    final uri = _buildUri(
      path,
      null,
      resolvedUrl,
    );

    _log(
      'POST',
      uri.toString(),
      body: body,
    );

    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _resolvedBaseUrl = null;

      throw ApiException(
        _backendUnavailableMessage(e),
      );
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resolvedUrl = await getBaseUrl();

    final uri = _buildUri(
      path,
      null,
      resolvedUrl,
    );

    _log(
      'PUT',
      uri.toString(),
      body: body,
    );

    try {
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _resolvedBaseUrl = null;

      throw ApiException(
        _backendUnavailableMessage(e),
      );
    }
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final resolvedUrl = await getBaseUrl();

    final uri = _buildUri(
      path,
      null,
      resolvedUrl,
    );

    _log(
      'DELETE',
      uri.toString(),
      body: body,
    );

    try {
      final request = http.Request(
        'DELETE',
        uri,
      );

      request.headers.addAll(_headers);

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamed = await request.send().timeout(_timeout);

      final response = await http.Response.fromStream(streamed);

      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      _resolvedBaseUrl = null;

      throw ApiException(
        _backendUnavailableMessage(e),
      );
    }
  }

  static Uri _buildUri(
    String path, [
    Map<String, String>? queryParams,
    String selectedBaseUrl = '',
  ]) {
    final base = selectedBaseUrl.endsWith('/')
        ? selectedBaseUrl
        : '$selectedBaseUrl/';

    final cleanPath = path.startsWith('/')
        ? path.substring(1)
        : path;

    final uri = Uri.parse('$base$cleanPath');

    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams,
      );
    }

    return uri;
  }

  static String _backendUnavailableMessage(Object? error) {
    String reason = 'Check your internet connection and server URL.';

    if (error is SocketException) {
      reason = 'Network error. Cannot reach the backend server.';
    } else if (error is TimeoutException) {
      reason = 'Connection timed out.';
    }

    final detail = error == null ? '' : ' Detail: $error';

    return 'Cannot reach backend.\n$reason$detail';
  }

  static Map<String, dynamic> _parse(
    http.Response response,
  ) {
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body)
          as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Invalid server response. '
        'Status: ${response.statusCode}',
      );
    }

    if (response.statusCode >= 400 ||
        body['success'] != true) {
      final msg =
          body['message']?.toString() ??
              'Unknown error';

      throw ApiException(msg);
    }

    return body;
  }

  static void _log(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) {
    if (kDebugMode) {
      debugPrint('[ApiClient] $method $url');

      if (body != null) {
        final safe =
            Map<String, dynamic>.from(body);

        if (safe.containsKey('password')) {
          safe['password'] = '***';
        }

        if (safe.containsKey('image_base64')) {
          safe['image_base64'] =
              '[base64 omitted]';
        }

        debugPrint(
          '[ApiClient] body => $safe',
        );
      }
    }
  }
}

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
