import 'dart:math';
import '../models/lottery_models.dart';

/// 核心统计分析引擎
class AnalysisEngine {
  final List<LotteryResult> historicalData;
  final LotteryType lotteryType;
  
  AnalysisEngine(this.historicalData, this.lotteryType);
  
  // ==================== 模块A：基础统计分析 ====================
  
  /// 计算单码频率统计
  List<NumberStatistics> calculateNumberFrequency({bool isFront = true}) {
    final maxNumber = isFront ? lotteryType.frontMax : lotteryType.backMax;
    final stats = <NumberStatistics>[];
    
    for (int num = 1; num <= maxNumber; num++) {
      stats.add(_calculateSingleNumberStats(num, isFront: isFront));
    }
    
    return stats;
  }
  
  /// 计算单个号码的统计数据
  NumberStatistics _calculateSingleNumberStats(int number, {bool isFront = true}) {
    // 总出现次数
    int totalCount = 0;
    int recent30Count = 0;
    int recent50Count = 0;
    int recent100Count = 0;
    
    // 遗漏值计算
    int currentMiss = 0;
    final missHistory = <int>[];
    int tempMiss = 0;
    
    // 遍历历史数据（从旧到新）
    final reversedData = historicalData.reversed.toList();
    
    for (int i = 0; i < reversedData.length; i++) {
      final result = reversedData[i];
      final numbers = isFront ? result.frontNumbers : result.backNumbers;
      
      if (numbers.contains(number)) {
        totalCount++;
        if (missHistory.isEmpty && currentMiss == 0) {
          currentMiss = tempMiss;
        }
        missHistory.add(tempMiss);
        tempMiss = 0;
        
        // 近期统计
        final recentIndex = reversedData.length - 1 - i;
        if (recentIndex < 30) recent30Count++;
        if (recentIndex < 50) recent50Count++;
        if (recentIndex < 100) recent100Count++;
      } else {
        tempMiss++;
      }
    }
    
    // 如果号码从未出现，当前遗漏为总期数
    if (totalCount == 0) {
      currentMiss = historicalData.length;
    }
    
    // 计算平均遗漏
    final avgMiss = missHistory.isEmpty ? 0.0 : missHistory.reduce((a, b) => a + b) / missHistory.length;
    
    // 最大遗漏
    final maxMiss = missHistory.isEmpty ? 0 : missHistory.reduce(max);
    
    // 频率
    final frequency = totalCount / historicalData.length;
    
    // 近期趋势（移动平均）
    final recentTrend = _calculateTrend(number, isFront: isFront);
    
    // 冷热状态
    final hotColdStatus = _determineHotColdStatus(currentMiss, avgMiss, recent30Count);
    
    return NumberStatistics(
      number: number,
      totalCount: totalCount,
      recent30Count: recent30Count,
      recent50Count: recent50Count,
      recent100Count: recent100Count,
      currentMiss: currentMiss,
      avgMiss: avgMiss.round(),
      maxMiss: maxMiss,
      frequency: frequency,
      recentTrend: recentTrend,
      hotColdStatus: hotColdStatus,
    );
  }
  
  /// 计算号码趋势
  double _calculateTrend(int number, {bool isFront = true}) {
    if (historicalData.length < 20) return 0;
    
    // 分成前后两段计算频率
    final mid = historicalData.length ~/ 2;
    int firstHalfCount = 0;
    int secondHalfCount = 0;
    
    for (int i = 0; i < historicalData.length; i++) {
      final numbers = isFront ? historicalData[i].frontNumbers : historicalData[i].backNumbers;
      if (numbers.contains(number)) {
        if (i < mid) {
          firstHalfCount++;
        } else {
          secondHalfCount++;
        }
      }
    }
    
    // 趋势：正数表示上升，负数表示下降
    return (secondHalfCount - firstHalfCount) / mid;
  }
  
  /// 判断冷热状态
  String _determineHotColdStatus(int currentMiss, double avgMiss, int recent30Count) {
    final expectedIn30 = 30 / (avgMiss + 1); // 期望在近30期出现的次数
    
    if (recent30Count > expectedIn30 * 1.3) {
      return 'hot';
    } else if (currentMiss > avgMiss * 1.5) {
      return 'cold';
    } else {
      return 'normal';
    }
  }
  
  /// 连号分析
  Map<String, dynamic> analyzeConsecutive() {
    int doubleConsecutive = 0;
    int tripleConsecutive = 0;
    final doubleConsecutiveIntervals = <int>[];
    final tripleConsecutiveIntervals = <int>[];
    
    int doubleInterval = 0;
    int tripleInterval = 0;
    
    for (final result in historicalData) {
      final numbers = result.frontNumbers;
      
      // 检查连号
      bool hasDouble = false;
      bool hasTriple = false;
      
      for (int i = 1; i < numbers.length; i++) {
        if (numbers[i] - numbers[i - 1] == 1) {
          hasDouble = true;
          if (i >= 2 && numbers[i] - numbers[i - 2] == 2) {
            hasTriple = true;
          }
        }
      }
      
      if (hasDouble) {
        doubleConsecutive++;
        if (doubleInterval > 0) doubleConsecutiveIntervals.add(doubleInterval);
        doubleInterval = 0;
      } else {
        doubleInterval++;
      }
      
      if (hasTriple) {
        tripleConsecutive++;
        if (tripleInterval > 0) tripleConsecutiveIntervals.add(tripleInterval);
        tripleInterval = 0;
      } else {
        tripleInterval++;
      }
    }
    
    return {
      'doubleConsecutiveRate': doubleConsecutive / historicalData.length,
      'tripleConsecutiveRate': tripleConsecutive / historicalData.length,
      'avgDoubleInterval': doubleConsecutiveIntervals.isEmpty ? 0 
          : doubleConsecutiveIntervals.reduce((a, b) => a + b) / doubleConsecutiveIntervals.length,
      'avgTripleInterval': tripleConsecutiveIntervals.isEmpty ? 0
          : tripleConsecutiveIntervals.reduce((a, b) => a + b) / tripleConsecutiveIntervals.length,
    };
  }
  
  /// 区间分布分析
  Map<String, Map<String, int>> analyzeZoneDistribution() {
    final distributionCounts = <String, int>{};
    
    for (final result in historicalData) {
      final zone = result.zoneDistribution;
      final key = zone.join('-');
      distributionCounts[key] = (distributionCounts[key] ?? 0) + 1;
    }
    
    // 计算比例
    final distributionRates = <String, Map<String, int>>{};
    distributionCounts.forEach((key, count) {
      distributionRates[key] = {
        'count': count,
        'rate': (count / historicalData.length * 100).round(),
      };
    });
    
    return distributionRates;
  }
  
  /// 奇偶比分析
  Map<String, double> analyzeOddEvenRatio() {
    final ratioCounts = <String, int>{};
    
    for (final result in historicalData) {
      ratioCounts[result.oddEvenRatio] = (ratioCounts[result.oddEvenRatio] ?? 0) + 1;
    }
    
    return ratioCounts.map((key, count) => 
        MapEntry(key, count / historicalData.length));
  }
  
  /// 大小比分析
  Map<String, double> analyzeBigSmallRatio() {
    final ratioCounts = <String, int>{};
    
    for (final result in historicalData) {
      ratioCounts[result.bigSmallRatio] = (ratioCounts[result.bigSmallRatio] ?? 0) + 1;
    }
    
    return ratioCounts.map((key, count) => 
        MapEntry(key, count / historicalData.length));
  }
  
  /// 和值分析
  Map<String, dynamic> analyzeSumValue() {
    final sumValues = historicalData.map((r) => r.sumValue).toList();
    sumValues.sort();
    
    final avg = sumValues.reduce((a, b) => a + b) / sumValues.length;
    final variance = sumValues.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / sumValues.length;
    final stdDev = sqrt(variance);
    
    // 计算正态分布的置信区间
    final lowerBound = avg - 1.645 * stdDev; // 90%置信区间
    final upperBound = avg + 1.645 * stdDev;
    
    return {
      'avg': avg,
      'stdDev': stdDev,
      'min': sumValues.first,
      'max': sumValues.last,
      'lowerBound90': lowerBound,
      'upperBound90': upperBound,
      'median': sumValues[sumValues.length ~/ 2],
    };
  }
  
  /// 跨度分析
  Map<String, dynamic> analyzeSpan() {
    final spans = historicalData.map((r) => r.span).toList();
    
    final spanCounts = <int, int>{};
    for (final span in spans) {
      spanCounts[span] = (spanCounts[span] ?? 0) + 1;
    }
    
    final avg = spans.reduce((a, b) => a + b) / spans.length;
    
    return {
      'avg': avg,
      'min': spans.reduce(min),
      'max': spans.reduce(max),
      'distribution': spanCounts,
    };
  }
  
  // ==================== 模块B：高级时序分析 ====================
  
  /// 移动平均分析
  Map<int, List<double>> calculateMovingAverage(int number, {bool isFront = true}) {
    final ma5 = <double>[];
    final ma10 = <double>[];
    final ma20 = <double>[];
    
    final appearanceSeries = <int>[];
    for (final result in historicalData) {
      final numbers = isFront ? result.frontNumbers : result.backNumbers;
      appearanceSeries.add(numbers.contains(number) ? 1 : 0);
    }
    
    for (int i = 0; i < appearanceSeries.length; i++) {
      if (i >= 4) {
        ma5.add(appearanceSeries.sublist(i - 4, i + 1).reduce((a, b) => a + b) / 5);
      }
      if (i >= 9) {
        ma10.add(appearanceSeries.sublist(i - 9, i + 1).reduce((a, b) => a + b) / 10);
      }
      if (i >= 19) {
        ma20.add(appearanceSeries.sublist(i - 19, i + 1).reduce((a, b) => a + b) / 20);
      }
    }
    
    return {
      5: ma5,
      10: ma10,
      20: ma20,
    };
  }
  
  /// 简化的自相关分析（ACF）
  List<double> calculateAutocorrelation(int maxLag, {bool isFront = true, int? targetNumber}) {
    final acf = <double>[];
    
    // 使用和值序列进行自相关分析
    final series = targetNumber != null
        ? historicalData.map((r) {
            final numbers = isFront ? r.frontNumbers : r.backNumbers;
            return numbers.contains(targetNumber) ? 1 : 0;
          }).toList()
        : historicalData.map((r) => r.sumValue.toDouble()).toList();
    
    final n = series.length;
    final mean = series.reduce((a, b) => a + b) / n;
    final variance = series.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / n;
    
    for (int lag = 0; lag <= maxLag; lag++) {
      double sum = 0;
      for (int i = lag; i < n; i++) {
        sum += (series[i] - mean) * (series[i - lag] - mean);
      }
      acf.add(sum / (n * variance));
    }
    
    return acf;
  }
  
  /// 马尔可夫链转移概率矩阵
  List<List<double>> buildMarkovTransitionMatrix({bool isFront = true}) {
    final maxNumber = isFront ? lotteryType.frontMax : lotteryType.backMax;
    
    // 构建转移矩阵
    final matrix = List.generate(
      maxNumber + 1,
      (_) => List.generate(maxNumber + 1, (_) => 0.0),
    );
    
    // 统计转移次数
    for (int i = 1; i < historicalData.length; i++) {
      final prevNumbers = isFront 
          ? historicalData[i - 1].frontNumbers 
          : historicalData[i - 1].backNumbers;
      final currNumbers = isFront 
          ? historicalData[i].frontNumbers 
          : historicalData[i].backNumbers;
      
      for (final prev in prevNumbers) {
        for (final curr in currNumbers) {
          matrix[prev][curr]++;
        }
      }
    }
    
    // 转换为概率
    for (int i = 1; i <= maxNumber; i++) {
      double rowSum = matrix[i].reduce((a, b) => a + b);
      if (rowSum > 0) {
        for (int j = 1; j <= maxNumber; j++) {
          matrix[i][j] /= rowSum;
        }
      }
    }
    
    return matrix;
  }
  
  /// 基于马尔可夫链预测
  List<double> predictByMarkov(List<int> lastNumbers, {bool isFront = true}) {
    final matrix = buildMarkovTransitionMatrix(isFront: isFront);
    final maxNumber = isFront ? lotteryType.frontMax : lotteryType.backMax;
    
    final probabilities = List.generate(maxNumber + 1, (_) => 0.0);
    
    // 基于上期出现的号码计算转移概率
    for (final num in lastNumbers) {
      for (int j = 1; j <= maxNumber; j++) {
        probabilities[j] += matrix[num][j] / lastNumbers.length;
      }
    }
    
    return probabilities;
  }
  
  // ==================== 模块D：红蓝联合分析 ====================
  
  /// 红蓝关联分析（双色球专用）
  Map<String, dynamic> analyzeRedBlueCorrelation() {
    if (!lotteryType.hasBackBall) return {};
    
    final blueToRedStats = <int, Map<String, dynamic>>{};
    
    for (final result in historicalData) {
      final blue = result.backNumbers.first;
      
      if (!blueToRedStats.containsKey(blue)) {
        blueToRedStats[blue] = {
          'count': 0,
          'redSumTotal': 0,
          'redOddCount': 0,
          'redBigCount': 0,
        };
      }
      
      blueToRedStats[blue]!['count']++;
      blueToRedStats[blue]!['redSumTotal'] += result.sumValue;
      blueToRedStats[blue]!['redOddCount'] += result.frontNumbers.where((n) => n % 2 == 1).length;
      blueToRedStats[blue]!['redBigCount'] += result.frontNumbers.where((n) => n > lotteryType.frontMax / 2).length;
    }
    
    // 计算平均值
    for (final blue in blueToRedStats.keys) {
      final count = blueToRedStats[blue]!['count'] as int;
      blueToRedStats[blue]!['avgRedSum'] = 
          blueToRedStats[blue]!['redSumTotal'] / count;
      blueToRedStats[blue]!['avgOddCount'] = 
          blueToRedStats[blue]!['redOddCount'] / count;
    }
    
    return blueToRedStats;
  }
  
  /// 获取综合分析报告
  Map<String, dynamic> generateAnalysisReport() {
    return {
      'numberFrequency': calculateNumberFrequency(),
      'backNumberFrequency': lotteryType.hasBackBall ? calculateNumberFrequency(isFront: false) : null,
      'consecutiveAnalysis': analyzeConsecutive(),
      'zoneDistribution': analyzeZoneDistribution(),
      'oddEvenRatio': analyzeOddEvenRatio(),
      'bigSmallRatio': analyzeBigSmallRatio(),
      'sumValueAnalysis': analyzeSumValue(),
      'spanAnalysis': analyzeSpan(),
      'redBlueCorrelation': lotteryType.hasBackBall ? analyzeRedBlueCorrelation() : null,
    };
  }
}
