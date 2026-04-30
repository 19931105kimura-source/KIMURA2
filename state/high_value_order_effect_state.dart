import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/server_config.dart';

class HighValueOrderEffectState extends ChangeNotifier {
  static const _keyThreshold = 'high_value_order_effect_threshold_v2';
  static const _keyAnimationPath = 'high_value_order_effect_animation_path_v2';
  static const _keyDisplayMs = 'high_value_order_effect_display_ms_v1';

  static const int defaultThreshold = 100000;
  static const String defaultAnimationPath = '';
  static const int defaultDisplayMs = 4200;

  int _threshold = defaultThreshold;
  String _animationPath = defaultAnimationPath;
  int _displayMs = defaultDisplayMs;

  int get threshold => _threshold;
  String get animationPath => _animationPath;
  int get displayMs => _displayMs;
  bool get isEnabled => _animationPath.trim().isNotEmpty;
  Future<void> load() async {
     await _loadFromServer();
    await _saveLocal();
    notifyListeners();
  }

  Future<void> save({
    required int threshold,
    required String animationPath,
    required int displayMs,
    }) async {
    final normalizedThreshold = threshold < 1 ? 1 : threshold;
    final normalizedPath = animationPath.trim();
    final normalizedDisplayMs = displayMs.clamp(1000, 15000);
    await _saveToServer(
      threshold: normalizedThreshold,
      animationPath: normalizedPath,
      displayMs: normalizedDisplayMs,
    );
    await _saveLocal(
      threshold: normalizedThreshold,
      animationPath: normalizedPath,
      displayMs: normalizedDisplayMs,
    );

    _threshold = normalizedThreshold;
    _animationPath = normalizedPath;
    _displayMs = normalizedDisplayMs;
    notifyListeners();
  }

  Future<void> _loadFromServer() async {
    try {
      final res = await http.get(ServerConfig.api('/api/high-value-order-effect'));
      if (res.statusCode != 200) {
        await _loadLocal();
        return;
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      _threshold = (decoded['threshold'] as num?)?.toInt() ?? defaultThreshold;
      _animationPath = (decoded['animationPath'] as String? ?? '').trim();
      _displayMs = (decoded['displayMs'] as num?)?.toInt() ?? defaultDisplayMs;
      if (_threshold < 1) _threshold = 1;
        _displayMs = _displayMs.clamp(1000, 15000);
    } catch (_) {
      await _loadLocal();
    }
  }

  Future<void> _saveToServer({
    required int threshold,
    required String animationPath,
    required int displayMs,
  }) async {
    await http.post(
      ServerConfig.api('/api/high-value-order-effect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'threshold': threshold,
        'animationPath': animationPath,
        'displayMs': displayMs,
      }),
    );
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _threshold = prefs.getInt(_keyThreshold) ?? defaultThreshold;
    _animationPath = (prefs.getString(_keyAnimationPath) ?? defaultAnimationPath)
        .trim();
    _displayMs = prefs.getInt(_keyDisplayMs) ?? defaultDisplayMs;
    if (_threshold < 1) _threshold = 1;
  }

  Future<void> _saveLocal({
    int? threshold,
    String? animationPath,
    int? displayMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThreshold, threshold ?? _threshold);
    await prefs.setString(_keyAnimationPath, animationPath ?? _animationPath);
    await prefs.setInt(_keyDisplayMs, displayMs ?? _displayMs);
  }
}