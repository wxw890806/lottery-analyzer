import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/lottery_models.dart';
import 'database_service.dart';

/// 彩票数据获取服务
/// 由于真实的彩票API需要授权，这里提供模拟数据源和真实API框架
class DataFetchService {
  static final DataFetchService instance = DataFetchService._internal();
  DataFetchService._internal();
  
  final DatabaseService _db = DatabaseService.instance;
  
  // API端点配置（真实环境需要替换为实际API）
  static const Map<String, String> apiEndpoints = {
    'ssq': 'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice',
    'dlt': 'https://webapi.sporttery.cn/gateway/lottery/getHistoryPageListV1.qry',
    '3d': 'https://www.cwl.gov.cn/cwl_admin/front/cwlkj/search/kjxx/findDrawNotice',
  };
  
  /// 获取指定彩种的历史数据
  Future<List<LotteryResult>> fetchHistoryData(LotteryType type, {int count = 500}) async {
    try {
      // 尝试从真实API获取
      // final realData = await _fetchFromRealApi(type, count);
      // if (realData.isNotEmpty) return realData;
      
      // 使用模拟数据（开发阶段）
      return await _generateMockData(type, count);
    } catch (e) {
      // 网络错误时返回本地数据或模拟数据
      final localData = await _db.getLotteryResults(type, limit: count);
      if (localData.isNotEmpty) return localData;
      return await _generateMockData(type, count);
    }
  }
  
  /// 从真实API获取数据
  Future<List<LotteryResult>> _fetchFromRealApi(LotteryType type, int count) async {
    final endpoint = apiEndpoints[type.code];
    if (endpoint == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$endpoint?name=${type.code}&issueCount=$count'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseApiResponse(type, data);
      }
    } catch (e) {
      // API调用失败
      print('API fetch error: $e');
    }
    return [];
  }
  
  /// 解析API响应
  List<LotteryResult> _parseApiResponse(LotteryType type, dynamic data) {
    // 根据不同API的响应格式解析
    // 这里需要根据实际API文档调整
    return [];
  }
  
  /// 生成模拟历史数据（用于开发和测试）
  Future<List<LotteryResult>> _generateMockData(LotteryType type, int count) async {
    final random = Random();
    final results = <LotteryResult>[];
    final now = DateTime.now();
    
    // 模拟数据包含一些统计规律
    for (int i = count - 1; i >= 0; i--) {
      final drawDate = now.subtract(Duration(days: i * 3)); // 每3天一期
      
      // 生成前区号码（带一定规律的随机）
      final frontNumbers = _generateWeightedNumbers(
        min: 1,
        max: type.frontMax,
        count: type.frontCount,
        random: random,
      );
      
      // 生成后区号码
      List<int> backNumbers = [];
      if (type.hasBackBall) {
        backNumbers = _generateWeightedNumbers(
          min: 1,
          max: type.backMax,
          count: type.backCount,
          random: random,
        );
      }
      
      // 生成期号
      final year = drawDate.year;
      final issueInYear = ((count - i) * 3 + 100).toString().padLeft(3, '0');
      final issueNo = '$year$issueInYear';
      
      results.add(LotteryResult(
        issueNo: issueNo,
        type: type,
        frontNumbers: frontNumbers,
        backNumbers: backNumbers,
        drawDate: drawDate,
        salesAmount: random.nextInt(500000000) + 100000000,
        poolAmount: random.nextInt(10000000000) + 500000000,
        firstPrizeCount: random.nextInt(20),
        firstPrizeAmount: random.nextInt(10000000) + 500000,
      ));
    }
    
    // 保存到数据库
    await _db.insertLotteryResults(results);
    
    return results;
  }
  
  /// 生成带权重的随机号码（模拟真实分布规律）
  List<int> _generateWeightedNumbers({
    required int min,
    required int max,
    required int count,
    required Random random,
  }) {
    final numbers = <int>[];
    final availableNumbers = List.generate(max, (i) => i + 1);
    
    // 创建权重（中间号码权重略高）
    final weights = <double>[];
    final mid = (min + max) / 2;
    for (int n in availableNumbers) {
      final distance = (n - mid).abs();
      weights.add(1.0 + (mid - distance) / mid * 0.3);
    }
    
    // 加权随机选择
    while (numbers.length < count) {
      final selected = _weightedRandomSelect(availableNumbers, weights, random);
      if (!numbers.contains(selected)) {
        numbers.add(selected);
      }
    }
    
    numbers.sort();
    return numbers;
  }
  
  /// 加权随机选择
  int _weightedRandomSelect(List<int> items, List<double> weights, Random random) {
    final totalWeight = weights.reduce((a, b) => a + b);
    var r = random.nextDouble() * totalWeight;
    
    for (int i = 0; i < items.length; i++) {
      r -= weights[i];
      if (r <= 0) return items[i];
    }
    return items.last;
  }
  
  /// 获取最新开奖结果
  Future<LotteryResult?> fetchLatestResult(LotteryType type) async {
    final results = await fetchHistoryData(type, count: 1);
    return results.isNotEmpty ? results.first : null;
  }
  
  /// 检查是否有新数据
  Future<bool> hasNewData(LotteryType type) async {
    final latestLocal = await _db.getLatestResult(type);
    if (latestLocal == null) return true;
    
    // 检查开奖时间
    final now = DateTime.now();
    final drawDate = latestLocal.drawDate;
    
    // 双色球每周二、四、日开奖
    // 大乐透每周一、三、六开奖
    // 这里简化处理，实际需要根据开奖日历判断
    return now.difference(drawDate).inHours > 24;
  }
  
  /// 同步数据
  Future<int> syncData(LotteryType type, {int maxCount = 500}) async {
    final results = await fetchHistoryData(type, count: maxCount);
    if (results.isNotEmpty) {
      await _db.updateSyncLog(type.code, results.first.issueNo, results.length);
    }
    return results.length;
  }
  
  /// 验证数据完整性
  Future<bool> verifyDataIntegrity(LotteryType type) async {
    // 实际实现需要与官方数据比对
    // 这里简化处理
    return true;
  }
}

/// 官方数据源配置
class OfficialDataSource {
  final String name;
  final String baseUrl;
  final bool requiresAuth;
  
  const OfficialDataSource({
    required this.name,
    required this.baseUrl,
    this.requiresAuth = false,
  });
  
  static const OfficialDataSource chinaWelfareLottery = OfficialDataSource(
    name: '中国福利彩票',
    baseUrl: 'https://www.cwl.gov.cn',
    requiresAuth: false,
  );
  
  static const OfficialDataSource chinaSportLottery = OfficialDataSource(
    name: '中国体育彩票',
    baseUrl: 'https://www.lottery.gov.cn',
    requiresAuth: false,
  );
}

/// 备用数据源配置
class BackupDataSource {
  final String name;
  final String baseUrl;
  final bool requiresAuth;
  
  const BackupDataSource({
    required this.name,
    required this.baseUrl,
    this.requiresAuth = true,
  });
  
  static const BackupDataSource lottery500 = BackupDataSource(
    name: '500彩票网',
    baseUrl: 'https://datachart.500.com',
    requiresAuth: true,
  );
  
  static const BackupDataSource lotteryWinner = BackupDataSource(
    name: '彩票大赢家',
    baseUrl: 'https://www.cpdyj.com',
    requiresAuth: true,
  );
}
