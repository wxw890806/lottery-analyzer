import 'package:flutter/material.dart';
import '../models/lottery_models.dart';
import '../services/database_service.dart';
import '../services/data_fetch_service.dart';

/// 彩票数据状态管理
class LotteryProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final DataFetchService _dataService = DataFetchService.instance;
  
  LotteryType _selectedType = LotteryType.doubleColor;
  List<LotteryResult> _results = [];
  LotteryResult? _latestResult;
  bool _isLoading = false;
  String? _error;
  
  LotteryType get selectedType => _selectedType;
  List<LotteryResult> get results => _results;
  LotteryResult? get latestResult => _latestResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void setSelectedType(LotteryType type) {
    _selectedType = type;
    loadData();
  }
  
  Future<void> loadData({int count = 500}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 检查本地数据
      _results = await _db.getLotteryResults(_selectedType, limit: count);
      
      if (_results.isEmpty) {
        // 本地无数据，从网络获取
        _results = await _dataService.fetchHistoryData(_selectedType, count: count);
      }
      
      _latestResult = _results.isNotEmpty ? _results.first : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> syncData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _dataService.syncData(_selectedType);
      await loadData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refresh() async {
    await syncData();
  }
}
