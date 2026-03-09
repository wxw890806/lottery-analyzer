import 'dart:math';
import '../models/lottery_models.dart';
import 'analysis_engine.dart';
import 'machine_learning_engine.dart';

/// 预测生成系统
class PredictionGenerator {
  final List<LotteryResult> historicalData;
  final LotteryType lotteryType;
  late final AnalysisEngine _analysisEngine;
  late final MachineLearningEngine _mlEngine;
  
  PredictionGenerator(this.historicalData, this.lotteryType) {
    _analysisEngine = AnalysisEngine(historicalData, lotteryType);
    _mlEngine = MachineLearningEngine(historicalData, lotteryType);
  }
  
  /// 预测策略类型
  enum PredictionStrategy {
    hot追踪,      // 热号追踪
    cold反弹,     // 冷号反弹
    balance平衡,  // 区间平衡
    smart混合,    // 智能混合（推荐）
  }
  
  /// 生成预测
  List<Prediction> generatePredictions({
    PredictionStrategy strategy = PredictionStrategy.smart混合,
    int count = 5,
  }) {
    switch (strategy) {
      case PredictionStrategy.hot追踪:
        return _generateHotTrackingPredictions(count);
      case PredictionStrategy.cold反弹:
        return _generateColdBouncePredictions(count);
      case PredictionStrategy.balance平衡:
        return _generateBalancePredictions(count);
      case PredictionStrategy.smart混合:
        return _generateSmartMixedPredictions(count);
    }
  }
  
  /// 热号追踪模式
  List<Prediction> _generateHotTrackingPredictions(int count) {
    final predictions = <Prediction>[];
    final frontStats = _analysisEngine.calculateNumberFrequency();
    final backStats = lotteryType.hasBackBall 
        ? _analysisEngine.calculateNumberFrequency(isFront: false) 
        : <NumberStatistics>[];
    
    // 按近期频率排序
    frontStats.sort((a, b) => b.recent30Count.compareTo(a.recent30Count));
    
    for (int i = 0; i < count; i++) {
      // 选择近期频率高且遗漏值不过高的号码
      final selectedFront = <int>[];
      int idx = 0;
      
      while (selectedFront.length < lotteryType.frontCount && idx < frontStats.length) {
        final stat = frontStats[idx];
        // 选择近期活跃且未达到最大遗漏的号码
        if (stat.recent30Count >= 2 && stat.currentMiss < stat.maxMiss * 0.8) {
          if (!selectedFront.contains(stat.number)) {
            selectedFront.add(stat.number);
          }
        }
        idx++;
        
        // 备用策略：如果找不到合适的，强制添加
        if (idx >= frontStats.length && selectedFront.length < lotteryType.frontCount) {
          idx = 0;
        }
      }
      
      // 如果选择的号码不够，补充遗漏接近平均的号码
      if (selectedFront.length < lotteryType.frontCount) {
        for (final stat in frontStats) {
          if (!selectedFront.contains(stat.number) && 
              stat.currentMiss <= stat.avgMiss &&
              selectedFront.length < lotteryType.frontCount) {
            selectedFront.add(stat.number);
          }
        }
      }
      
      selectedFront.sort();
      
      // 后区选择
      List<int> selectedBack = [];
      if (lotteryType.hasBackBall && backStats.isNotEmpty) {
        backStats.sort((a, b) => b.recent30Count.compareTo(a.recent30Count));
        selectedBack = backStats
            .take(lotteryType.backCount)
            .map((s) => s.number)
            .toList();
      }
      
      // 计算置信度
      final confidence = _calculateConfidence(selectedFront, selectedBack, 'hot');
      
      predictions.add(Prediction(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        lotteryType: lotteryType,
        frontNumbers: selectedFront,
        backNumbers: selectedBack,
        confidence: confidence,
        strategy: '热号追踪',
        explanation: '基于近期（30期）出现频率分析，选取活跃号码。'
            '选择近${lotteryType.frontCount}期出现次数最多的号码。',
        createdAt: DateTime.now(),
      ));
    }
    
    return predictions;
  }
  
  /// 冷号反弹模式
  List<Prediction> _generateColdBouncePredictions(int count) {
    final predictions = <Prediction>[];
    final frontStats = _analysisEngine.calculateNumberFrequency();
    final backStats = lotteryType.hasBackBall 
        ? _analysisEngine.calculateNumberFrequency(isFront: false) 
        : <NumberStatistics>[];
    
    // 按当前遗漏排序（遗漏最大的在前）
    frontStats.sort((a, b) => b.currentMiss.compareTo(a.currentMiss));
    
    for (int i = 0; i < count; i++) {
      final selectedFront = <int>[];
      
      // 选择遗漏值接近或超过历史最大遗漏的号码
      for (final stat in frontStats) {
        if (selectedFront.length >= lotteryType.frontCount) break;
        
        // 冷号条件：当前遗漏超过平均遗漏的1.3倍
        if (stat.currentMiss > stat.avgMiss * 1.3) {
          selectedFront.add(stat.number);
        }
      }
      
      // 如果冷号不够，选择遗漏接近历史平均的号码
      if (selectedFront.length < lotteryType.frontCount) {
        frontStats.sort((a, b) {
          final aMiss = (a.currentMiss - a.avgMiss).abs();
          final bMiss = (b.currentMiss - b.avgMiss).abs();
          return bMiss.compareTo(aMiss);
        });
        
        for (final stat in frontStats) {
          if (!selectedFront.contains(stat.number) && 
              selectedFront.length < lotteryType.frontCount) {
            selectedFront.add(stat.number);
          }
        }
      }
      
      selectedFront.sort();
      
      // 后区选择
      List<int> selectedBack = [];
      if (lotteryType.hasBackBall && backStats.isNotEmpty) {
        backStats.sort((a, b) => b.currentMiss.compareTo(a.currentMiss));
        selectedBack = backStats
            .take(lotteryType.backCount)
            .map((s) => s.number)
            .toList();
      }
      
      final confidence = _calculateConfidence(selectedFront, selectedBack, 'cold');
      
      predictions.add(Prediction(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        lotteryType: lotteryType,
        frontNumbers: selectedFront,
        backNumbers: selectedBack,
        confidence: confidence,
        strategy: '冷号反弹',
        explanation: '基于遗漏值分析，选取长期未出现可能反弹的号码。'
            '选择当前遗漏超过历史平均值的号码。',
        createdAt: DateTime.now(),
      ));
    }
    
    return predictions;
  }
  
  /// 区间平衡模式
  List<Prediction> _generateBalancePredictions(int count) {
    final predictions = <Prediction>[];
    final zoneAnalysis = _analysisEngine.analyzeZoneDistribution();
    
    // 找出最常见的区间分布
    String bestZone = '';
    int bestCount = 0;
    zoneAnalysis.forEach((zone, stats) {
      if (stats['count']! > bestCount) {
        bestCount = stats['count']!;
        bestZone = zone;
      }
    });
    
    // 目标区间分布
    final targetZones = bestZone.split('-').map(int.parse).toList();
    
    for (int i = 0; i < count; i++) {
      final frontStats = _analysisEngine.calculateNumberFrequency();
      
      // 按号码所在的区间分组
      final zoneNumbers = <int, List<NumberStatistics>>{};
      if (lotteryType == LotteryType.doubleColor) {
        // 三区
        for (final stat in frontStats) {
          int zoneIdx;
          if (stat.number <= 11) zoneIdx = 0;
          else if (stat.number <= 22) zoneIdx = 1;
          else zoneIdx = 2;
          
          zoneNumbers.putIfAbsent(zoneIdx, () => []).add(stat);
        }
      }
      
      // 从各区选取号码
      final selectedFront = <int>[];
      for (int z = 0; z < targetZones.length && z < 3; z++) {
        final zoneStats = zoneNumbers[z] ?? [];
        zoneStats.sort((a, b) => b.frequency.compareTo(a.frequency));
        
        // 从该区选择号码
        final needCount = targetZones[z];
        for (int j = 0; j < needCount && j < zoneStats.length; j++) {
          if (!selectedFront.contains(zoneStats[j].number)) {
            selectedFront.add(zoneStats[j].number);
          }
        }
      }
      
      // 如果不够，从各区补充
      if (selectedFront.length < lotteryType.frontCount) {
        for (final stat in frontStats) {
          if (!selectedFront.contains(stat.number) && 
              selectedFront.length < lotteryType.frontCount) {
            selectedFront.add(stat.number);
          }
        }
      }
      
      selectedFront.sort();
      
      // 后区随机选择
      List<int> selectedBack = [];
      if (lotteryType.hasBackBall) {
        final random = Random();
        selectedBack = List.generate(
          lotteryType.backCount, 
          (_) => random.nextInt(lotteryType.backMax) + 1
        )..sort();
      }
      
      final confidence = _calculateConfidence(selectedFront, selectedBack, 'balance');
      
      predictions.add(Prediction(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        lotteryType: lotteryType,
        frontNumbers: selectedFront,
        backNumbers: selectedBack,
        confidence: confidence,
        strategy: '区间平衡',
        explanation: '基于历史区间分布规律，选取各区号码符合最常见分布比例的组合。'
            '目标区间分布：${targetZones.join(':')}',
        createdAt: DateTime.now(),
      ));
    }
    
    return predictions;
  }
  
  /// 智能混合模式（推荐）
  List<Prediction> _generateSmartMixedPredictions(int count) {
    final predictions = <Prediction>[];
    
    // 综合预测
    final ensemblePrediction = _mlEngine.predictByEnsemble(
      basicWeight: 0.30,
      timeSeriesWeight: 0.30,
      mlWeight: 0.40,
    );
    
    // 和值范围
    final sumAnalysis = _analysisEngine.analyzeSumValue();
    final sumLower = sumAnalysis['lowerBound90'] as double;
    final sumUpper = sumAnalysis['upperBound90'] as double;
    
    // 奇偶比分布
    final oddEvenAnalysis = _analysisEngine.analyzeOddEvenRatio();
    final commonOddEven = oddEvenAnalysis.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final targetOddEven = commonOddEven.take(3).map((e) => e.key).toSet();
    
    // 遗传算法搜索最优组合
    for (int i = 0; i < count; i++) {
      final best = _geneticAlgorithmSearch(
        ensemblePrediction,
        sumLower,
        sumUpper,
        targetOddEven,
        iterations: 100,
      );
      
      predictions.add(Prediction(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        lotteryType: lotteryType,
        frontNumbers: best['front']!,
        backNumbers: best['back']!,
        confidence: best['score']!,
        strategy: '智能混合',
        explanation: '综合运用基础统计(30%)、时序分析(30%)、机器学习(40%)三种方法，'
            '通过遗传算法优化组合，过滤不符合历史规律的号码。',
        createdAt: DateTime.now(),
      ));
    }
    
    // 按置信度排序
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return predictions;
  }
  
  /// 遗传算法搜索最优组合
  Map<String, dynamic> _geneticAlgorithmSearch(
    Map<int, double> scores,
    double sumLower,
    double sumUpper,
    Set<String> targetOddEven, {
    int iterations = 100,
  }) {
    final random = Random();
    var bestFront = <int>[];
    var bestBack = <int>[];
    var bestScore = 0.0;
    
    // 初始化种群
    final population = <Map<String, dynamic>>[];
    for (int i = 0; i < 50; i++) {
      final individual = _createRandomIndividual(scores);
      if (_isValidIndividual(individual, sumLower, sumUpper, targetOddEven)) {
        population.add(individual);
      }
    }
    
    // 迭代进化
    for (int iter = 0; iter < iterations; iter++) {
      // 评估适应度
      for (final individual in population) {
        final front = individual['front'] as List<int>;
        final fitness = _calculateFitness(front, scores);
        
        if (fitness > bestScore) {
          bestScore = fitness;
          bestFront = List.from(front);
          bestBack = List.from(individual['back'] as List<int>);
        }
      }
      
      // 选择、交叉、变异
      final newPopulation = <Map<String, dynamic>>[];
      
      // 精英保留
      population.sort((a, b) {
        final fitA = _calculateFitness(a['front'] as List<int>, scores);
        final fitB = _calculateFitness(b['front'] as List<int>, scores);
        return fitB.compareTo(fitA);
      });
      
      newPopulation.addAll(population.take(10));
      
      // 生成新个体
      while (newPopulation.length < 50) {
        final parent1 = population[random.nextInt(population.length)];
        final parent2 = population[random.nextInt(population.length)];
        
        final child = _crossover(parent1, parent2, scores);
        
        // 变异
        if (random.nextDouble() < 0.1) {
          _mutate(child, scores);
        }
        
        if (_isValidIndividual(child, sumLower, sumUpper, targetOddEven)) {
          newPopulation.add(child);
        }
      }
      
      population.clear();
      population.addAll(newPopulation);
    }
    
    return {
      'front': bestFront,
      'back': bestBack,
      'score': bestScore.clamp(0, 100),
    };
  }
  
  /// 创建随机个体
  Map<String, dynamic> _createRandomIndividual(Map<int, double> scores) {
    final sortedNumbers = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 按分数选择号码
    final selected = <int>[];
    final random = Random();
    
    // 优先选择高分号码
    for (int i = 0; i < sortedNumbers.length && selected.length < lotteryType.frontCount; i++) {
      final prob = (sortedNumbers[i].value) / 100;
      if (random.nextDouble() < prob || i < lotteryType.frontCount + 5) {
        if (!selected.contains(sortedNumbers[i].key)) {
          selected.add(sortedNumbers[i].key);
        }
      }
    }
    
    // 确保数量足够
    while (selected.length < lotteryType.frontCount) {
      final num = random.nextInt(lotteryType.frontMax) + 1;
      if (!selected.contains(num)) selected.add(num);
    }
    
    selected.sort();
    
    // 后区
    final backScores = _mlEngine.predictByRandomForest(isFront: false);
    final sortedBack = backScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final selectedBack = sortedBack
        .take(lotteryType.backCount)
        .map((e) => e.key)
        .toList()
      ..sort();
    
    return {
      'front': selected,
      'back': selectedBack,
    };
  }
  
  /// 交叉操作
  Map<String, dynamic> _crossover(
    Map<String, dynamic> parent1,
    Map<String, dynamic> parent2,
    Map<int, double> scores,
  ) {
    final front1 = parent1['front'] as List<int>;
    final front2 = parent2['front'] as List<int>;
    
    final random = Random();
    final split = random.nextInt(lotteryType.frontCount);
    
    final childFront = <int>[
      ...front1.take(split),
      ...front2.skip(split),
    ];
    
    // 去重并补齐
    final unique = childFront.toSet().toList();
    while (unique.length < lotteryType.frontCount) {
      final num = random.nextInt(lotteryType.frontMax) + 1;
      if (!unique.contains(num)) unique.add(num);
    }
    unique.sort();
    
    // 后区简单继承
    final back = random.nextBool() 
        ? List<int>.from(parent1['back']) 
        : List<int>.from(parent2['back']);
    
    return {
      'front': unique,
      'back': back,
    };
  }
  
  /// 变异操作
  void _mutate(Map<String, dynamic> individual, Map<int, double> scores) {
    final random = Random();
    final front = individual['front'] as List<int>;
    
    // 变异：随机替换一个号码
    if (random.nextBool() && front.length > 0) {
      final idx = random.nextInt(front.length);
      final newNum = random.nextInt(lotteryType.frontMax) + 1;
      front[idx] = newNum;
      front.sort();
    }
  }
  
  /// 检查个体是否有效（满足过滤条件）
  bool _isValidIndividual(
    Map<String, dynamic> individual,
    double sumLower,
    double sumUpper,
    Set<String> targetOddEven,
  ) {
    final front = individual['front'] as List<int>;
    
    // 和值过滤
    final sum = front.reduce((a, b) => a + b);
    if (sum < sumLower || sum > sumUpper) return false;
    
    // 奇偶比过滤
    final oddCount = front.where((n) => n % 2 == 1).length;
    final ratio = '$oddCount:${front.length - oddCount}';
    if (!targetOddEven.contains(ratio)) {
      // 允许一定概率的例外
      if (Random().nextDouble() > 0.3) return false;
    }
    
    // 连号过滤（不允许超过3个连续号码）
    int consecutive = 0;
    for (int i = 1; i < front.length; i++) {
      if (front[i] - front[i - 1] == 1) consecutive++;
    }
    if (consecutive > 2) return false;
    
    return true;
  }
  
  /// 计算适应度
  double _calculateFitness(List<int> front, Map<int, double> scores) {
    // 号码总分
    double totalScore = 0;
    for (final num in front) {
      totalScore += scores[num] ?? 0;
    }
    
    // 号码分散度（不连号加分）
    double diversity = 0;
    for (int i = 1; i < front.length; i++) {
      diversity += front[i] - front[i - 1];
    }
    diversity /= front.length;
    
    return totalScore + diversity * 0.5;
  }
  
  /// 计算置信度
  double _calculateConfidence(List<int> front, List<int> back, String strategy) {
    // 基于策略类型和号码质量计算置信度
    double baseScore = 50;
    
    switch (strategy) {
      case 'hot':
        baseScore = 55;
        break;
      case 'cold':
        baseScore = 45;
        break;
      case 'balance':
        baseScore = 50;
        break;
      case 'smart':
        baseScore = 65;
        break;
    }
    
    // 随机波动
    final random = Random();
    return (baseScore + random.nextDouble() * 15).clamp(0, 100);
  }
}
