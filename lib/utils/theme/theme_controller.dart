import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const _storageKey = 'theme_mode';
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;

  Rx<ThemeMode> get themeMode => _themeMode;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final box = GetStorage();
    final storedValue = box.read<int>(_storageKey);
    if (storedValue != null && storedValue >= 0 && storedValue < ThemeMode.values.length) {
      _themeMode.value = ThemeMode.values[storedValue];
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode.value = mode;
    GetStorage().write(_storageKey, mode.index);
  }
} 