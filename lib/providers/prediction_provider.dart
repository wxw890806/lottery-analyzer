import 'package:flutter/material.dart';
import '../models/lottery_models.dart';
import '../services/prediction_generator.dart';
import '../services/backtest_service.dart';
import '../services/database_service.dart';

/// 预测状态管理
class PredictionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  
  List<LotteryResult> _historicalData = [];
  PredictionGenerator? _generator;
  List<Prediction> _predictions = [];
  BacktestResult? _backtestResult;
  PredictionGenerator.PredictionStrategy _currentStrategy = 
      PredictionGenerator.PredictionStrategy.smart混合;
  bool _isPredicting = false;
  bool _isBacktesting = false;
  
  List<Prediction> get predictions => _predictions;
  BacktestResult? get backtestResult => _backtestResult;
  PredictionGenerator.PredictionStrategy get currentStrategy => _currentStrategy;
  bool get isPredicting => _isPredicting;
  bool get isBacktesting => _isBacktesting;
  
  void setHistoricalData(List<LotteryResult> data) {
    _historicalData = data;
    if (data.isNotEmpty) {
      _generator = PredictionGenerator(data, data.first.type);
    }
  }
  
  void setStrategy(PredictionGenerator.PredictionStrategy strategy) {
    _currentStrategy = strategy;
    notifyListeners();
  }
  
  Future<void> generatePredictions({int count = 5}) async {
    if (_generator == null || _historicalData.isEmpty) return;
    
    _isPredicting = true;
    notifyListeners();
    
    try {
      _predictions = _generator!.generatePredictions(
        strategy: _currentStrategy,
        count: count,
      );
      
      // 保存到数据库
      for (final prediction in _predictions) {
        await _db.savePrediction(prediction);
      }
    } catch (e) {
      debugPrint('预测错误: $e');
    } finally {
      _isPredicting = false;
      notifyListeners();
    }
  }
  
  Future<void> runBacktest({
    int trainSize = 100,
    int testSize = 30,
  }) async {
    if (_historicalData.isEmpty) return;
    
    _isBacktesting = true;
    notifyListeners();
    
    try {
      final backtestService = BacktestService(_historicalData, _historicalData.first.type);
      _backtestResult = await backtestService.rollingBacktest(
        trainSize: trainSize,
        testSize: testSize,
        strategy: _currentStrategy,
      );
      
      // 保存回测结果
      await _db.saveBacktestResult(_backtestResult!, _historicalData.first.type.code);
    } catch (e) {
      debugPrint('回测错误: $e');
    } finally {
      _isBacktesting = false;
      notifyListeners();
    }
  }
  
  Future<List<Prediction>> getHistoryPredictions({int limit = 10}) async {
    if (_historicalData.isEmpty) return [];
    return await _db.getPredictions(_historicalData.first.type, limit: limit);
  }
  
  /// 获取策略说明
  String getStrategyDescription(PredictionGenerator.PredictionStrategy strategy) {
    switch (strategy) {
      case PredictionGenerator.PredictionStrategy.hot追踪:
        return '选择近期出现频率最高的号码，适合趋势明显的期次';
      case PredictionGenerator.PredictionStrategy.cold反弹:
        return '选择遗漏值接近历史最大值的号码，适合冷号反弹期';
      case PredictionGenerator.PredictionStrategy.balance平衡:
        return '保证各区间号码分布符合历史最常见比例';
      case PredictionGenerator.PredictionStrategy.smart混合:
        return '综合多种算法，通过遗传算法优化，推荐使用';
    }
  }
}
