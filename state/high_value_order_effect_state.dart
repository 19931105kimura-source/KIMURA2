import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighValueOrderEffectState extends ChangeNotifier {
  static const _keyThreshold = 'high_value_order_effect_threshold_v1';
  static const _keyAnimationPath = 'high_value_order_effect_animation_path_v1';

  static const int defaultThreshold = 100000;
  static const String defaultAnimationPath =
      '/uploads/promos/promo_1773918193087.mp4';

  int _threshold = defaultThreshold;
  String _animationPath = defaultAnimationPath;

  int get threshold => _threshold;
  String get animationPath => _animationPath;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _threshold = prefs.getInt(_keyThreshold) ?? defaultThreshold;
    _animationPath = prefs.getString(_keyAnimationPath) ?? defaultAnimationPath;
    notifyListeners();
  }

  Future<void> save({
    required int threshold,
    required String animationPath,
  }) async {
    final normalizedThreshold = threshold < 1 ? 1 : threshold;
    final normalizedPath = animationPath.trim().isEmpty
        ? defaultAnimationPath
        : animationPath.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThreshold, normalizedThreshold);
    await prefs.setString(_keyAnimationPath, normalizedPath);

    _threshold = normalizedThreshold;
    _animationPath = normalizedPath;
    notifyListeners();
  }
}