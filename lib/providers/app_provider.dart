import 'package:flutter/material.dart';

/// 应用状态管理
class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;
  String _loadingMessage = '';
  
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  void showLoading(String message) {
    _isLoading = true;
    _loadingMessage = message;
    notifyListeners();
  }
  
  void hideLoading() {
    _isLoading = false;
    _loadingMessage = '';
    notifyListeners();
  }
}
