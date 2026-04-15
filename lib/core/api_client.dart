// ============================================================
//  lib/core/api_client.dart
//
//  Usage anywhere in the app:
//    final res = await ApiClient.get('/api/v1/profile/me/');
//    final res = await ApiClient.patch('/api/v1/profile/me/', body: {...});
//
//  For public endpoints (login, signup, reset password):
//    final res = await ApiClient.post('/api/v1/auth/login/', body: {...}, requiresAuth: false);
//
//  For file uploads:
//    final res = await ApiClient.uploadMultipart('/api/v1/events/uploads/banner/',
//      files: [await http.MultipartFile.fromPath('banner', imageFile.path)]);
// ============================================================

import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'https://campusbuddybackend-production-3d8a.up.railway.app';

class ApiClient {
  ApiClient._();

  static const _kAccess  = 'accessToken';
  static const _kRefresh = 'refreshToken';

  // ── Read tokens ────────────────────────────────────────────
  static Future<String> _accessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess) ?? '';
  }

  static Future<String> _refreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh) ?? '';
  }

  // ── Save tokens after login / refresh ─────────────────────
  //
  //  Call this after login AND after any manual token parse.
  //  Accepts both SimpleJWT snake_case keys ('access', 'refresh')
  //  and legacy camelCase keys ('accessToken', 'refreshToken').
  //
  //  Convenience helper — parse a raw auth response body and save:
  //    await ApiClient.saveTokensFromJson(jsonDecode(res.body));
  static Future<void> saveTokens(String access, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess,  access);
    await p.setString(_kRefresh, refresh);
  }

  static Future<void> saveTokensFromJson(Map<String, dynamic> json) async {
    // SimpleJWT returns 'access' / 'refresh' (snake_case).
    // Fall back to camelCase in case the backend wraps them.
    final access  = json['access']       as String?
                 ?? json['accessToken']  as String?
                 ?? '';
    final refresh = json['refresh']      as String?
                 ?? json['refreshToken'] as String?
                 ?? '';

    if (access.isEmpty) {
      dev.log('[ApiClient] saveTokensFromJson: no access token found in ${ json.keys.toList()}');
      return;
    }
    await saveTokens(access, refresh);
  }

  // ── Clear tokens (force re-login) ─────────────────────────
  static Future<void> clearTokens() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }

  // ── Public getters ─────────────────────────────────────────
  static String get baseUrl => _baseUrl;

  static Future<String> getAccessToken() async => _accessToken();

  // ── Build headers ──────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _accessToken();
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Silent token refresh ───────────────────────────────────
  //
  //  FIX: SimpleJWT returns snake_case keys ('access', 'refresh').
  //  The old code looked for 'accessToken' / 'refreshToken', which
  //  always resolved to null → newAccess was always '' → clearTokens()
  //  was called silently → every request after expiry lost its auth
  //  header → 404 on protected endpoints.
  static Future<bool> refresh() async {
    final token = await _refreshToken();
    if (token.isEmpty) return false;

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': token}),
      );

      dev.log('[ApiClient] refresh → ${res.statusCode}');

      if (res.statusCode == 200) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;

        dev.log('[ApiClient] refresh keys: ${j.keys.toList()}');

        // Accept both key formats
        final newAccess  = j['access']       as String?
                        ?? j['accessToken']  as String?
                        ?? '';
        final newRefresh = j['refresh']      as String?
                        ?? j['refreshToken'] as String?
                        ?? token; // keep old refresh if server doesn't rotate

        if (newAccess.isNotEmpty) {
          await saveTokens(newAccess, newRefresh);
          dev.log('[ApiClient] token refreshed successfully');
          return true;
        }

        dev.log('[ApiClient] refresh: access token missing in response');
      }
    } catch (e) {
      dev.log('[ApiClient] refresh error: $e');
    }

    await clearTokens();
    return false;
  }

  // ── Core executor: send → 401 → refresh → retry once ──────
  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> h) fn, {
    bool requiresAuth = true,
  }) async {
    final res = await fn(await _headers(requiresAuth: requiresAuth));

    if (!requiresAuth || res.statusCode != 401) return res;

    final ok = await refresh();
    if (!ok) return res; // still 401 — caller should navigate to login

    return fn(await _headers(requiresAuth: true)); // retry with new token
  }

  // ── Public HTTP verbs ──────────────────────────────────────

  static Future<http.Response> get(
    String path, {
    bool requiresAuth = true,
  }) =>
      _send(
        (h) => http.get(Uri.parse('$_baseUrl$path'), headers: h),
        requiresAuth: requiresAuth,
      );

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) =>
      _send(
        (h) => http.post(
          Uri.parse('$_baseUrl$path'),
          headers: h,
          body: body != null ? jsonEncode(body) : null,
        ),
        requiresAuth: requiresAuth,
      );

  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) =>
      _send(
        (h) => http.patch(
          Uri.parse('$_baseUrl$path'),
          headers: h,
          body: body != null ? jsonEncode(body) : null,
        ),
        requiresAuth: requiresAuth,
      );

  static Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) =>
      _send(
        (h) => http.delete(
          Uri.parse('$_baseUrl$path'),
          headers: h,
          body: body != null ? jsonEncode(body) : null,
        ),
        requiresAuth: requiresAuth,
      );

  // ── Multipart upload (POST) ────────────────────────────────
  static Future<http.Response> uploadMultipart(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    final uri     = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    if (requiresAuth) {
      final token = await _accessToken();
      if (token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.addAll(files);
    if (fields != null) request.fields.addAll(fields);

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ── Multipart PUT / PATCH ──────────────────────────────────
  static Future<http.Response> uploadMultipartWithMethod(
    String path, {
    required String method,
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    final uri     = Uri.parse('$_baseUrl$path');
    final request = http.MultipartRequest(method, uri);

    if (requiresAuth) {
      final token = await _accessToken();
      if (token.isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.addAll(files);
    if (fields != null) request.fields.addAll(fields);

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
}