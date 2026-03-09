import 'dart:math';
import '../models/lottery_models.dart';
import 'analysis_engine.dart';

/// 机器学习预测引擎
/// 包含特征工程、模型预测、集成学习等功能
class MachineLearningEngine {
  final List<LotteryResult> historicalData;
  final LotteryType lotteryType;
  late final AnalysisEngine _analysisEngine;
  
  MachineLearningEngine(this.historicalData, this.lotteryType) {
    _analysisEngine = AnalysisEngine(historicalData, lotteryType);
  }
  
  // ==================== 特征工程 ====================
  
  /// 构建特征向量（每个号码的特征）
  Map<int, Map<String, double>> buildFeatureVectors({bool isFront = true}) {
    final features = <int, Map<String, double>>{};
    final maxNumber = isFront ? lotteryType.frontMax : lotteryType.backMax;
    final recentData = historicalData.take(50).toList();
    
    for (int num = 1; num <= maxNumber; num++) {
      features[num] = _extractFeaturesForNumber(num, recentData, isFront: isFront);
    }
    
    return features;
  }
  
  /// 提取单个号码的特征
  Map<String, double> _extractFeaturesForNumber(
    int number,
    List<LotteryResult> data, {
    bool isFront = true,
  }) {
    // 基础特征
    int totalCount = 0;
    int recent10Count = 0;
    int recent20Count = 0;
    int recent30Count = 0;
    int currentMiss = 0;
    final missHistory = <int>[];
    int tempMiss = 0;
    
    // 时序特征：近5期出现序列
    final recent5Appearances = <int>[];
    
    final reversedData = data.reversed.toList();
    for (int i = 0; i < reversedData.length; i++) {
      final numbers = isFront ? reversedData[i].frontNumbers : reversedData[i].backNumbers;
      final appears = numbers.contains(number) ? 1 : 0;
      
      if (appears == 1) {
        totalCount++;
        missHistory.add(tempMiss);
        tempMiss = 0;
        
        if (i >= data.length - 10) recent10Count++;
        if (i >= data.length - 20) recent20Count++;
        if (i >= data.length - 30) recent30Count++;
      } else {
        tempMiss++;
      }
      
      if (i >= data.length - 5) {
        recent5Appearances.add(appears);
      }
    }
    
    if (totalCount == 0) currentMiss = data.length;
    else currentMiss = tempMiss;
    
    // 计算平均遗漏
    final avgMiss = missHistory.isEmpty 
        ? data.length.toDouble() 
        : missHistory.reduce((a, b) => a + b) / missHistory.length;
    
    // 特征计算
    final frequency = totalCount / data.length;
    
    // 移动平均特征
    final ma5 = recent5Appearances.isEmpty 
        ? 0.0 
        : recent5Appearances.reduce((a, b) => a + b) / recent5Appearances.length;
    
    // 遗漏比率（当前遗漏/平均遗漏）
    final missRatio = avgMiss > 0 ? currentMiss / avgMiss : 1.0;
    
    // 趋势特征（基于最近30期vs之前30期）
    final half = data.length ~/ 2;
    int firstHalf = 0, secondHalf = 0;
    for (int i = 0; i < data.length; i++) {
      final numbers = isFront ? data[i].frontNumbers : data[i].backNumbers;
      if (numbers.contains(number)) {
        if (i < half) firstHalf++;
        else secondHalf++;
      }
    }
    final trend = half > 0 ? (secondHalf - firstHalf) / half : 0.0;
    
    // 周期性特征（简化的自相关）
    final periodicity = _calculateSimplePeriodicity(number, data, isFront: isFront);
    
    return {
      'frequency': frequency,
      'recent10Freq': recent10Count / 10,
      'recent20Freq': recent20Count / 20,
      'recent30Freq': recent30Count / 30,
      'currentMiss': currentMiss.toDouble(),
      'avgMiss': avgMiss,
      'maxMiss': missHistory.isEmpty ? 0 : missHistory.reduce(max),
      'missRatio': missRatio,
      'movingAverage5': ma5,
      'trend': trend,
      'periodicity': periodicity,
    };
  }
  
  /// 简化周期性计算
  double _calculateSimplePeriodicity(int number, List<LotteryResult> data, {bool isFront = true}) {
    // 找出号码出现的间隔
    final intervals = <int>[];
    int lastAppear = -1;
    
    for (int i = 0; i < data.length; i++) {
      final numbers = isFront ? data[i].frontNumbers : data[i].backNumbers;
      if (numbers.contains(number)) {
        if (lastAppear >= 0) {
          intervals.add(i - lastAppear);
        }
        lastAppear = i;
      }
    }
    
    if (intervals.isEmpty) return 0;
    
    // 计算标准差/均值作为规律性指标（越小越规律）
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    if (avg == 0) return 0;
    
    final variance = intervals.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / intervals.length;
    final stdDev = sqrt(variance);
    
    // 返回规律性分数（标准差越小越规律）
    return 1 / (1 + stdDev);
  }
  
  // ==================== 随机森林模拟 ====================
  
  /// 随机森林预测（模拟实现）
  Map<int, double> predictByRandomForest({bool isFront = true}) {
    final features = buildFeatureVectors(isFront: isFront);
    final predictions = <int, double>{};
    
    // 简化的随机森林逻辑：多棵决策树的加权投票
    // 实际上这里使用特征组合来预测
    
    for (final entry in features.entries) {
      final num = entry.key;
      final feat = entry.value;
      
      // 多维度评分
      double score = 0;
      
      // 1. 频率评分 (权重: 25%)
      score += feat['frequency']! * 100 * 0.25;
      
      // 2. 近期频率评分 (权重: 30%)
      score += feat['recent30Freq']! * 100 * 0.30;
      
      // 3. 遗漏反弹评分 (权重: 20%)
      // 遗漏接近平均遗漏时得分高
      final missRatio = feat['missRatio']!;
      if (missRatio > 0.8 && missRatio < 1.2) {
        score += 50 * 0.20;
      } else if (missRatio > 1.2) {
        score += (missRatio - 1) * 20 * 0.20;
      }
      
      // 4. 趋势评分 (权重: 15%)
      score += (feat['trend']! + 1) * 30 * 0.15;
      
      // 5. 周期性评分 (权重: 10%)
      score += feat['periodicity']! * 50 * 0.10;
      
      predictions[num] = score.clamp(0, 100);
    }
    
    return predictions;
  }
  
  // ==================== LSTM模拟 ====================
  
  /// LSTM时序预测（简化模拟）
  Map<int, double> predictByLSTM({bool isFront = true}) {
    final predictions = <int, double>{};
    final maxNumber = isFront ? lotteryType.frontMax : lotteryType.backMax;
    
    // 使用移动平均和趋势来模拟LSTM的长期依赖
    for (int num = 1; num <= maxNumber; num++) {
      final ma = _analysisEngine.calculateMovingAverage(num, isFront: isFront);
      
      double score = 50; // 基础分数
      
      // 5期移动平均
      if (ma[5]!.isNotEmpty) {
        final ma5 = ma[5]!.last;
        // 高于平均值说明近期活跃
        final avgMA5 = ma[5]!.reduce((a, b) => a + b) / ma[5]!.length;
        if (ma5 > avgMA5 * 1.2) {
          score += 20;
        } else if (ma5 < avgMA5 * 0.8) {
          score -= 15;
        }
      }
      
      // 20期移动平均趋势
      if (ma[20]!.isNotEmpty) {
        final recentMA20 = ma[20]!.take(5).toList();
        final olderMA20 = ma[20]!.skip(ma[20]!.length - 5).toList();
        if (recentMA20.isNotEmpty && olderMA20.isNotEmpty) {
          final recentAvg = recentMA20.reduce((a, b) => a + b) / recentMA20.length;
          final olderAvg = olderMA20.reduce((a, b) => a + b) / olderMA20.length;
          score += (recentAvg - olderAvg) * 100;
        }
      }
      
      predictions[num] = score.clamp(0, 100);
    }
    
    return predictions;
  }
  
  // ==================== XGBoost模拟 ====================
  
  /// XGBoost预测（简化模拟）
  Map<int, double> predictByXGBoost({bool isFront = true}) {
    final features = buildFeatureVectors(isFront: isFront);
    final predictions = <int, double>{};
    
    // 简化的梯度提升逻辑
    for (final entry in features.entries) {
      final num = entry.key;
      final feat = entry.value;
      
      // 使用更复杂的特征组合
      double score = 0;
      
      // 非线性特征组合
      final freqProduct = feat['frequency']! * feat['recent30Freq']!;
      final missProduct = feat['missRatio']! * feat['trend']!;
      
      // 综合评分
      score = freqProduct * 80 + 
              feat['movingAverage5']! * 60 +
              (feat['periodicity']! * 30) +
              (missProduct > 0 ? missProduct * 20 : 0);
      
      // 归一化到0-100
      predictions[num] = (score + 50).clamp(0, 100);
    }
    
    return predictions;
  }
  
  // ==================== 集成学习 ====================
  
  /// 集成预测（加权投票）
  Map<int, double> predictByEnsemble({
    double basicWeight = 0.30,
    double timeSeriesWeight = 0.30,
    double mlWeight = 0.40,
  }) {
    // 基础统计
    final rfPredictions = predictByRandomForest();
    final lstmPredictions = predictByLSTM();
    final xgbPredictions = predictByXGBoost();
    
    // 归一化
    final normalizedRF = _normalizePredictions(rfPredictions);
    final normalizedLSTM = _normalizePredictions(lstmPredictions);
    final normalizedXGB = _normalizePredictions(xgbPredictions);
    
    // 加权融合
    final ensemble = <int, double>{};
    final maxNumber = lotteryType.frontMax;
    
    for (int num = 1; num <= maxNumber; num++) {
      ensemble[num] = 
          (normalizedRF[num] ?? 0) * basicWeight +
          (normalizedLSTM[num] ?? 0) * timeSeriesWeight +
          (normalizedXGB[num] ?? 0) * mlWeight;
    }
    
    return ensemble;
  }
  
  /// 归一化预测分数
  Map<int, double> _normalizePredictions(Map<int, double> predictions) {
    if (predictions.isEmpty) return {};
    
    final maxVal = predictions.values.reduce(max);
    final minVal = predictions.values.reduce(min);
    final range = maxVal - minVal;
    
    if (range == 0) {
      return predictions.map((k, v) => MapEntry(k, 50.0));
    }
    
    return predictions.map((k, v) => 
        MapEntry(k, ((v - minVal) / range * 100)));
  }
  
  /// 动态权重调整（基于历史回测）
  Map<String, double> adjustWeights(Map<String, double> baseWeights) {
    // 简化实现：返回基础权重
    // 实际应用中需要根据回测准确率动态调整
    return baseWeights;
  }
}
