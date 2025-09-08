import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption {
  system('system', 'システム設定に従う'),
  light('light', 'ライト'),
  dark('dark', 'ダーク');

  const ThemeOption(this.value, this.displayName);
  final String value;
  final String displayName;

  static ThemeOption fromString(String value) {
    return ThemeOption.values.firstWhere(
      (theme) => theme.value == value,
      orElse: () => ThemeOption.system,
    );
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemeOption.system:
        return ThemeMode.system;
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
    }
  }
}

class ThemeState {
  const ThemeState({
    this.themeOption = ThemeOption.system,
    this.isLoading = false,
  });

  final ThemeOption themeOption;
  final bool isLoading;

  ThemeState copyWith({
    ThemeOption? themeOption,
    bool? isLoading,
  }) {
    return ThemeState(
      themeOption: themeOption ?? this.themeOption,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  static const String _themeKey = 'theme_preference';

  Future<void> _loadTheme() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final prefs = await SharedPreferences.getInstance();
      final themeValue = prefs.getString(_themeKey) ?? ThemeOption.system.value;
      final themeOption = ThemeOption.fromString(themeValue);
      
      state = state.copyWith(
        themeOption: themeOption,
        isLoading: false,
      );
    } catch (e) {
      // エラー時はデフォルトのシステム設定を使用
      state = state.copyWith(
        themeOption: ThemeOption.system,
        isLoading: false,
      );
    }
  }

  Future<void> setTheme(ThemeOption themeOption) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeOption.value);
      
      state = state.copyWith(
        themeOption: themeOption,
        isLoading: false,
      );
    } catch (e) {
      // エラー時は状態を元に戻す
      state = state.copyWith(isLoading: false);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);
