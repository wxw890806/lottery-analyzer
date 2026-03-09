import 'package:flutter/material.dart';
import '../models/lottery_models.dart';
import '../services/analysis_engine.dart';

/// 分析状态管理
class AnalysisProvider extends ChangeNotifier {
  List<LotteryResult> _historicalData = [];
  Map<String, dynamic>? _analysisReport;
  List<NumberStatistics>? _frontNumberStats;
  List<NumberStatistics>? _backNumberStats;
  bool _isAnalyzing = false;
  
  Map<String, dynamic>? get analysisReport => _analysisReport;
  List<NumberStatistics>? get frontNumberStats => _frontNumberStats;
  List<NumberStatistics>? get backNumberStats => _backNumberStats;
  bool get isAnalyzing => _isAnalyzing;
  
  void setHistoricalData(List<LotteryResult> data) {
    _historicalData = data;
    analyze();
  }
  
  Future<void> analyze() async {
    if (_historicalData.isEmpty) return;
    
    _isAnalyzing = true;
    notifyListeners();
    
    try {
      final engine = AnalysisEngine(_historicalData, _historicalData.first.type);
      
      // 生成完整分析报告
      _analysisReport = engine.generateAnalysisReport();
      
      // 号码频率统计
      _frontNumberStats = engine.calculateNumberFrequency();
      if (_historicalData.first.type.hasBackBall) {
        _backNumberStats = engine.calculateNumberFrequency(isFront: false);
      }
    } catch (e) {
      debugPrint('分析错误: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
  
  /// 获取热力图数据
  List<Map<String, dynamic>> getHotMapData({bool isFront = true}) {
    final stats = isFront ? _frontNumberStats : _backNumberStats;
    if (stats == null) return [];
    
    return stats.map((s) => {
      'number': s.number,
      'value': s.recent30Count,
      'color': _getHeatColor(s.recent30Count / 10),
    }).toList();
  }
  
  Color _getHeatColor(double ratio) {
    if (ratio > 0.8) return Colors.red.shade700;
    if (ratio > 0.6) return Colors.orange;
    if (ratio > 0.4) return Colors.yellow;
    if (ratio > 0.2) return Colors.lightGreen;
    return Colors.green.shade100;
  }
  
  /// 获取遗漏值排行榜
  List<NumberStatistics> getMissRanking({bool isFront = true, int limit = 10}) {
    final stats = isFront ? _frontNumberStats : _backNumberStats;
    if (stats == null) return [];
    
    final sorted = List<NumberStatistics>.from(stats);
    sorted.sort((a, b) => b.currentMiss.compareTo(a.currentMiss));
    return sorted.take(limit).toList();
  }
}
