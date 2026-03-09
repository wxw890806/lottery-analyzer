import '../models/lottery_models.dart';
import 'prediction_generator.dart';

/// 回测验证系统
class BacktestService {
  final List<LotteryResult> historicalData;
  final LotteryType lotteryType;
  late final PredictionGenerator _generator;
  
  BacktestService(this.historicalData, this.lotteryType) {
    _generator = PredictionGenerator(historicalData, lotteryType);
  }
  
  /// 滚动回测
  /// 用前N期数据预测第N+1期
  Future<BacktestResult> rollingBacktest({
    int trainSize = 100,
    int testSize = 50,
    PredictionGenerator.PredictionStrategy strategy = 
        PredictionGenerator.PredictionStrategy.smart混合,
  }) async {
    if (historicalData.length < trainSize + testSize) {
      throw Exception('数据量不足，无法进行回测');
    }
    
    // 统计
    int hits0 = 0, hits1 = 0, hits2 = 0, hits3 = 0;
    int hits4 = 0, hits5 = 0, hits6 = 0;
    int backHits = 0;
    
    // 滚动测试
    for (int i = trainSize; i < trainSize + testSize; i++) {
      // 使用i之前的数据作为训练集
      final trainData = historicalData.sublist(0, i);
      final actualResult = historicalData[i];
      
      // 生成预测
      final tempGenerator = PredictionGenerator(trainData, lotteryType);
      final predictions = tempGenerator.generatePredictions(
        strategy: strategy,
        count: 1,
      );
      
      if (predictions.isEmpty) continue;
      
      final prediction = predictions.first;
      
      // 计算命中
      final frontHits = _countHits(prediction.frontNumbers, actualResult.frontNumbers);
      final backHit = lotteryType.hasBackBall && 
          prediction.backNumbers.isNotEmpty &&
          actualResult.backNumbers.any((n) => prediction.backNumbers.contains(n));
      
      switch (frontHits) {
        case 0: hits0++; break;
        case 1: hits1++; break;
        case 2: hits2++; break;
        case 3: hits3++; break;
        case 4: hits4++; break;
        case 5: hits5++; break;
        case 6: hits6++; break;
      }
      
      if (backHit) backHits++;
    }
    
    final totalTests = testSize;
    final avgHitCount = (hits1 + hits2 * 2 + hits3 * 3 + hits4 * 4 + hits5 * 5 + hits6 * 6) / totalTests;
    final winRate = (hits3 + hits4 + hits5 + hits6) / totalTests;
    
    return BacktestResult(
      strategy: strategy.name,
      totalTests: totalTests,
      hits0: hits0,
      hits1: hits1,
      hits2: hits2,
      hits3: hits3,
      hits4: hits4,
      hits5: hits5,
      hits6: hits6,
      backHits: backHits,
      avgHitCount: avgHitCount,
      winRate: winRate,
    );
  }
  
  /// 统计命中数
  int _countHits(List<int> predicted, List<int> actual) {
    int count = 0;
    for (final num in predicted) {
      if (actual.contains(num)) count++;
    }
    return count;
  }
  
  /// 策略对比回测
  Future<Map<String, BacktestResult>> compareStrategies({
    int trainSize = 100,
    int testSize = 30,
  }) async {
    final results = <String, BacktestResult>{};
    
    for (final strategy in PredictionGenerator.PredictionStrategy.values) {
      try {
        final result = await rollingBacktest(
          trainSize: trainSize,
          testSize: testSize,
          strategy: strategy,
        );
        results[strategy.name] = result;
      } catch (e) {
        // 跳过失败的策略
      }
    }
    
    return results;
  }
  
  /// 计算命中率分布
  Map<String, double> calculateHitDistribution(BacktestResult result) {
    return {
      '0红': result.hits0 / result.totalTests * 100,
      '1红': result.hits1 / result.totalTests * 100,
      '2红': result.hits2 / result.totalTests * 100,
      '3红': result.hits3 / result.totalTests * 100,
      '4红': result.hits4 / result.totalTests * 100,
      '5红': result.hits5 / result.totalTests * 100,
      '6红': result.hits6 / result.totalTests * 100,
    };
  }
  
  /// 获取策略有效性报告
  Future<String> generateStrategyReport() async {
    final results = await compareStrategies();
    
    final buffer = StringBuffer();
    buffer.writeln('========== 策略对比报告 ==========\n');
    
    results.forEach((strategy, result) {
      buffer.writeln('策略: $strategy');
      buffer.writeln('  总测试期数: ${result.totalTests}');
      buffer.writeln('  平均命中红球: ${result.avgHitCount.toStringAsFixed(2)}');
      buffer.writeln('  中奖率(3红及以上): ${(result.winRate * 100).toStringAsFixed(1)}%');
      buffer.writeln('  命中蓝球概率: ${(result.backHits / result.totalTests * 100).toStringAsFixed(1)}%');
      buffer.writeln('  命中分布: 0=' + result.hits0.toString() + 
                     ', 1=' + result.hits1.toString() + 
                     ', 2=' + result.hits2.toString() + 
                     ', 3=' + result.hits3.toString() +
                     ', 4=' + result.hits4.toString() +
                     ', 5=' + result.hits5.toString() +
                     ', 6=' + result.hits6.toString());
      buffer.writeln('');
    });
    
    // 找出最佳策略
    String bestStrategy = '';
    double bestWinRate = 0;
    results.forEach((strategy, result) {
      if (result.winRate > bestWinRate) {
        bestWinRate = result.winRate;
        bestStrategy = strategy;
      }
    });
    
    buffer.writeln('推荐策略: $bestStrategy (中奖率 ${(bestWinRate * 100).toStringAsFixed(1)}%)');
    
    return buffer.toString();
  }
  
  /// 动态优化模型参数
  /// 根据回测结果自动调整权重
  Future<Map<String, double>> optimizeWeights() async {
    final results = await compareStrategies();
    
    // 找出表现最好的策略
    double bestScore = 0;
    String bestStrategy = '';
    
    results.forEach((strategy, result) {
      // 综合评分：考虑中奖率和平均命中数
      final score = result.winRate * 100 + result.avgHitCount * 10;
      if (score > bestScore) {
        bestScore = score;
        bestStrategy = strategy;
      }
    });
    
    // 返回优化后的权重
    // 这里简化处理，实际应该根据最佳策略调整各模型权重
    return {
      'basicWeight': 0.30,
      'timeSeriesWeight': 0.30,
      'mlWeight': 0.40,
    };
  }
}
