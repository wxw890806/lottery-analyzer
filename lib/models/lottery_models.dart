/// 彩票类型枚举
enum LotteryType {
  doubleColor('双色球', 'ssq', 33, 6, 16, 1),
  superLotto('大乐透', 'dlt', 35, 5, 12, 2),
  welfare3d('福3D', '3d', 9, 3, 0, 0),
  play3('排列3', 'pls', 9, 3, 0, 0),
  sevenStar('七星彩', 'qxc', 9, 7, 0, 0),
  sevenLuck('七乐彩', 'qlc', 30, 7, 0, 0);

  final String displayName;
  final String code;
  final int frontMax;    // 前区最大号码
  final int frontCount;  // 前区选号数量
  final int backMax;     // 后区最大号码
  final int backCount;   // 后区选号数量

  const LotteryType(this.displayName, this.code, this.frontMax, this.frontCount, this.backMax, this.backCount);
  
  bool get hasBackBall => backMax > 0;
}

/// 开奖结果模型
class LotteryResult {
  final String issueNo;           // 期号
  final LotteryType type;         // 彩种
  final List<int> frontNumbers;   // 前区号码（红球）
  final List<int> backNumbers;    // 后区号码（蓝球）
  final DateTime drawDate;        // 开奖日期
  final int? salesAmount;         // 销售额（分）
  final int? poolAmount;          // 奖池金额（分）
  final int? firstPrizeCount;     // 一等奖注数
  final int? firstPrizeAmount;    // 一等奖金额（分）
  
  const LotteryResult({
    required this.issueNo,
    required this.type,
    required this.frontNumbers,
    required this.backNumbers,
    required this.drawDate,
    this.salesAmount,
    this.poolAmount,
    this.firstPrizeCount,
    this.firstPrizeAmount,
  });
  
  /// 计算和值
  int get sumValue => frontNumbers.fold(0, (sum, n) => sum + n);
  
  /// 计算跨度
  int get span => frontNumbers.last - frontNumbers.first;
  
  /// 奇偶比
  String get oddEvenRatio {
    final oddCount = frontNumbers.where((n) => n % 2 == 1).length;
    return '$oddCount:${frontNumbers.length - oddCount}';
  }
  
  /// 大小比（以中间值为界）
  String get bigSmallRatio {
    final mid = type.frontMax / 2;
    final bigCount = frontNumbers.where((n) => n > mid).length;
    return '$bigCount:${frontNumbers.length - bigCount}';
  }
  
  /// 连号数量
  int get consecutiveCount {
    int count = 0;
    for (int i = 1; i < frontNumbers.length; i++) {
      if (frontNumbers[i] - frontNumbers[i - 1] == 1) count++;
    }
    return count;
  }
  
  /// 区间分布
  List<int> get zoneDistribution {
    if (type == LotteryType.doubleColor) {
      // 双色球分三区：1-11, 12-22, 23-33
      return [
        frontNumbers.where((n) => n <= 11).length,
        frontNumbers.where((n) => n > 11 && n <= 22).length,
        frontNumbers.where((n) => n > 22).length,
      ];
    } else if (type == LotteryType.superLotto) {
      // 大乐透分五区
      return [
        frontNumbers.where((n) => n <= 7).length,
        frontNumbers.where((n) => n > 7 && n <= 14).length,
        frontNumbers.where((n) => n > 14 && n <= 21).length,
        frontNumbers.where((n) => n > 21 && n <= 28).length,
        frontNumbers.where((n) => n > 28).length,
      ];
    }
    return [];
  }
  
  Map<String, dynamic> toJson() {
    return {
      'issueNo': issueNo,
      'type': type.code,
      'frontNumbers': frontNumbers.join(','),
      'backNumbers': backNumbers.join(','),
      'drawDate': drawDate.toIso8601String(),
      'salesAmount': salesAmount,
      'poolAmount': poolAmount,
      'firstPrizeCount': firstPrizeCount,
      'firstPrizeAmount': firstPrizeAmount,
    };
  }
  
  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      issueNo: json['issueNo'],
      type: LotteryType.values.firstWhere((t) => t.code == json['type']),
      frontNumbers: (json['frontNumbers'] as String).split(',').map(int.parse).toList(),
      backNumbers: json['backNumbers'] != null && json['backNumbers'].isNotEmpty
          ? (json['backNumbers'] as String).split(',').map(int.parse).toList()
          : [],
      drawDate: DateTime.parse(json['drawDate']),
      salesAmount: json['salesAmount'],
      poolAmount: json['poolAmount'],
      firstPrizeCount: json['firstPrizeCount'],
      firstPrizeAmount: json['firstPrizeAmount'],
    );
  }
}

/// 号码统计模型
class NumberStatistics {
  final int number;
  final int totalCount;           // 总出现次数
  final int recent30Count;        // 近30期出现次数
  final int recent50Count;        // 近50期出现次数
  final int recent100Count;       // 近100期出现次数
  final int currentMiss;          // 当前遗漏期数
  final int avgMiss;              // 平均遗漏期数
  final int maxMiss;              // 最大遗漏期数
  final double frequency;         // 频率（出现次数/总期数）
  final double recentTrend;       // 近期趋势（正=上升，负=下降）
  final String hotColdStatus;     // 冷热状态
  
  const NumberStatistics({
    required this.number,
    required this.totalCount,
    required this.recent30Count,
    required this.recent50Count,
    required this.recent100Count,
    required this.currentMiss,
    required this.avgMiss,
    required this.maxMiss,
    required this.frequency,
    required this.recentTrend,
    required this.hotColdStatus,
  });
  
  /// 加权得分（综合考虑频率和遗漏）
  double get weightedScore {
    // 近期频率权重更高
    final recentWeight = recent30Count * 3 + recent50Count * 2 + recent100Count;
    // 遗漏值归一化
    final missScore = currentMiss > avgMiss ? (currentMiss - avgMiss) / avgMiss : 0;
    return recentWeight / 10 + missScore * 20;
  }
  
  Map<String, dynamic> toJson() => {
    'number': number,
    'totalCount': totalCount,
    'recent30Count': recent30Count,
    'recent50Count': recent50Count,
    'recent100Count': recent100Count,
    'currentMiss': currentMiss,
    'avgMiss': avgMiss,
    'maxMiss': maxMiss,
    'frequency': frequency,
    'recentTrend': recentTrend,
    'hotColdStatus': hotColdStatus,
  };
}

/// 预测模型
class Prediction {
  final String id;
  final LotteryType lotteryType;
  final List<int> frontNumbers;
  final List<int> backNumbers;
  final double confidence;        // 置信度 0-100
  final String strategy;          // 预测策略
  final String explanation;       // 分析说明
  final DateTime createdAt;
  final PredictionMetrics? metrics;
  
  const Prediction({
    required this.id,
    required this.lotteryType,
    required this.frontNumbers,
    required this.backNumbers,
    required this.confidence,
    required this.strategy,
    required this.explanation,
    required this.createdAt,
    this.metrics,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'lotteryType': lotteryType.code,
    'frontNumbers': frontNumbers.join(','),
    'backNumbers': backNumbers.join(','),
    'confidence': confidence,
    'strategy': strategy,
    'explanation': explanation,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// 预测评估指标
class PredictionMetrics {
  final double historicalAccuracy;    // 历史准确率
  final double recentHitRate;         // 近期命中率
  final int avgHitCount;              // 平均命中数
  final double strategyScore;         // 策略得分
  
  const PredictionMetrics({
    required this.historicalAccuracy,
    required this.recentHitRate,
    required this.avgHitCount,
    required this.strategyScore,
  });
}

/// 回测结果
class BacktestResult {
  final String strategy;
  final int totalTests;
  final int hits0;              // 命中0个号码的次数
  final int hits1;              // 命中1个号码的次数
  final int hits2;
  final int hits3;
  final int hits4;
  final int hits5;
  final int hits6;              // 命中6个号码的次数
  final int backHits;           // 命中蓝/后区的次数
  final double avgHitCount;     // 平均命中数
  final double winRate;         // 中奖率（至少3红）
  
  const BacktestResult({
    required this.strategy,
    required this.totalTests,
    required this.hits0,
    required this.hits1,
    required this.hits2,
    required this.hits3,
    required this.hits4,
    required this.hits5,
    required this.hits6,
    required this.backHits,
    required this.avgHitCount,
    required this.winRate,
  });
  
  Map<String, dynamic> toJson() => {
    'strategy': strategy,
    'totalTests': totalTests,
    'hits0': hits0,
    'hits1': hits1,
    'hits2': hits2,
    'hits3': hits3,
    'hits4': hits4,
    'hits5': hits5,
    'hits6': hits6,
    'backHits': backHits,
    'avgHitCount': avgHitCount,
    'winRate': winRate,
  };
}
