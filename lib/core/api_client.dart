// ============================================================
//  lib/core/api_client.dart
//
//  Usage anywhere in the app:
//    final res = await ApiClient.get('/api/v1/profile/me/');
//    final res = await ApiClient.patch('/api/v1/profile/me/', body: {...});
//
//  For public endpoints (login, signup, reset password):
//    final res = await ApiClient.post('/api/v1/auth/login/', body: {...}, requiresAuth: false);
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'https://campusbuddybackend-production.up.railway.app';

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
  static Future<void> saveTokens(String access, String refresh) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess,  access);
    await p.setString(_kRefresh, refresh);
  }

  // ── Clear tokens (force re-login) ─────────────────────────
  static Future<void> clearTokens() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
  }

  // ── Build headers — auth header skipped for public routes ──
  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _accessToken();
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Silent token refresh ───────────────────────────────────
  static Future<bool> refresh() async {
    final token = await _refreshToken();
    if (token.isEmpty) return false;

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': token}),
      );

      if (res.statusCode == 200) {
        final j          = jsonDecode(res.body) as Map<String, dynamic>;
        final newAccess  = j['accessToken']  as String? ?? '';
        final newRefresh = j['refreshToken'] as String? ?? token;
        if (newAccess.isNotEmpty) {
          await saveTokens(newAccess, newRefresh);
          return true;
        }
      }
    } catch (_) {}

    await clearTokens();
    return false;
  }

  // ── Core executor: send → 401 → refresh → retry once ──────
  // Only runs the refresh/retry logic for authenticated requests
  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> h) fn, {
    bool requiresAuth = true,
  }) async {
    final res = await fn(await _headers(requiresAuth: requiresAuth));

    // Don't attempt refresh for public endpoints
    if (!requiresAuth || res.statusCode != 401) return res;

    final ok = await refresh();
    if (!ok) return res; // still 401 — caller navigates to login

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
}