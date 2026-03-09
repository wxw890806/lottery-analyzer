import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lottery_models.dart';

/// 数据库服务 - 本地数据存储
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;
  
  DatabaseService._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lottery_analyzer.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // 开奖结果表
    await db.execute('''
      CREATE TABLE lottery_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        issue_no TEXT NOT NULL,
        lottery_type TEXT NOT NULL,
        front_numbers TEXT NOT NULL,
        back_numbers TEXT,
        draw_date TEXT NOT NULL,
        sales_amount INTEGER,
        pool_amount INTEGER,
        first_prize_count INTEGER,
        first_prize_amount INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE(issue_no, lottery_type)
      )
    ''');
    
    // 号码统计缓存表
    await db.execute('''
      CREATE TABLE number_statistics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lottery_type TEXT NOT NULL,
        number INTEGER NOT NULL,
        total_count INTEGER DEFAULT 0,
        recent30_count INTEGER DEFAULT 0,
        recent50_count INTEGER DEFAULT 0,
        recent100_count INTEGER DEFAULT 0,
        current_miss INTEGER DEFAULT 0,
        avg_miss REAL DEFAULT 0,
        max_miss INTEGER DEFAULT 0,
        frequency REAL DEFAULT 0,
        recent_trend REAL DEFAULT 0,
        hot_cold_status TEXT DEFAULT 'normal',
        updated_at TEXT NOT NULL,
        UNIQUE(lottery_type, number)
      )
    ''');
    
    // 预测记录表
    await db.execute('''
      CREATE TABLE predictions (
        id TEXT PRIMARY KEY,
        lottery_type TEXT NOT NULL,
        front_numbers TEXT NOT NULL,
        back_numbers TEXT,
        confidence REAL NOT NULL,
        strategy TEXT NOT NULL,
        explanation TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    
    // 回测结果表
    await db.execute('''
      CREATE TABLE backtest_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        strategy TEXT NOT NULL,
        lottery_type TEXT NOT NULL,
        total_tests INTEGER NOT NULL,
        hits0 INTEGER DEFAULT 0,
        hits1 INTEGER DEFAULT 0,
        hits2 INTEGER DEFAULT 0,
        hits3 INTEGER DEFAULT 0,
        hits4 INTEGER DEFAULT 0,
        hits5 INTEGER DEFAULT 0,
        hits6 INTEGER DEFAULT 0,
        back_hits INTEGER DEFAULT 0,
        avg_hit_count REAL DEFAULT 0,
        win_rate REAL DEFAULT 0,
        tested_at TEXT NOT NULL
      )
    ''');
    
    // 数据更新日志表
    await db.execute('''
      CREATE TABLE update_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lottery_type TEXT NOT NULL,
        last_issue TEXT NOT NULL,
        update_time TEXT NOT NULL,
        record_count INTEGER DEFAULT 0
      )
    ''');
    
    // 创建索引
    await db.execute('CREATE INDEX idx_results_type ON lottery_results(lottery_type)');
    await db.execute('CREATE INDEX idx_results_date ON lottery_results(draw_date)');
    await db.execute('CREATE INDEX idx_stats_type ON number_statistics(lottery_type)');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本升级逻辑
  }
  
  /// 初始化数据库
  Future<void> init() async {
    await database;
  }
  
  // ==================== 开奖结果操作 ====================
  
  /// 插入开奖结果
  Future<int> insertLotteryResult(LotteryResult result) async {
    final db = await database;
    return await db.insert(
      'lottery_results',
      {
        'issue_no': result.issueNo,
        'lottery_type': result.type.code,
        'front_numbers': result.frontNumbers.join(','),
        'back_numbers': result.backNumbers.join(','),
        'draw_date': result.drawDate.toIso8601String(),
        'sales_amount': result.salesAmount,
        'pool_amount': result.poolAmount,
        'first_prize_count': result.firstPrizeCount,
        'first_prize_amount': result.firstPrizeAmount,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 批量插入开奖结果
  Future<void> insertLotteryResults(List<LotteryResult> results) async {
    final db = await database;
    final batch = db.batch();
    for (final result in results) {
      batch.insert(
        'lottery_results',
        {
          'issue_no': result.issueNo,
          'lottery_type': result.type.code,
          'front_numbers': result.frontNumbers.join(','),
          'back_numbers': result.backNumbers.join(','),
          'draw_date': result.drawDate.toIso8601String(),
          'sales_amount': result.salesAmount,
          'pool_amount': result.poolAmount,
          'first_prize_count': result.firstPrizeCount,
          'first_prize_amount': result.firstPrizeAmount,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
  
  /// 获取指定彩种的所有开奖结果
  Future<List<LotteryResult>> getLotteryResults(LotteryType type, {int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lottery_results',
      where: 'lottery_type = ?',
      whereArgs: [type.code],
      orderBy: 'draw_date DESC',
      limit: limit,
    );
    return maps.map((map) => _mapToLotteryResult(map, type)).toList();
  }
  
  /// 获取最新的开奖结果
  Future<LotteryResult?> getLatestResult(LotteryType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lottery_results',
      where: 'lottery_type = ?',
      whereArgs: [type.code],
      orderBy: 'draw_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToLotteryResult(maps.first, type);
  }
  
  /// 获取开奖结果数量
  Future<int> getResultCount(LotteryType type) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lottery_results WHERE lottery_type = ?',
      [type.code],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  LotteryResult _mapToLotteryResult(Map<String, dynamic> map, LotteryType type) {
    return LotteryResult(
      issueNo: map['issue_no'],
      type: type,
      frontNumbers: (map['front_numbers'] as String).split(',').map(int.parse).toList(),
      backNumbers: map['back_numbers'] != null && (map['back_numbers'] as String).isNotEmpty
          ? (map['back_numbers'] as String).split(',').map(int.parse).toList()
          : [],
      drawDate: DateTime.parse(map['draw_date']),
      salesAmount: map['sales_amount'],
      poolAmount: map['pool_amount'],
      firstPrizeCount: map['first_prize_count'],
      firstPrizeAmount: map['first_prize_amount'],
    );
  }
  
  // ==================== 号码统计操作 ====================
  
  /// 保存号码统计
  Future<void> saveNumberStatistics(String lotteryType, List<NumberStatistics> stats) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    
    for (final stat in stats) {
      batch.insert(
        'number_statistics',
        {
          'lottery_type': lotteryType,
          'number': stat.number,
          'total_count': stat.totalCount,
          'recent30_count': stat.recent30Count,
          'recent50_count': stat.recent50Count,
          'recent100_count': stat.recent100Count,
          'current_miss': stat.currentMiss,
          'avg_miss': stat.avgMiss,
          'max_miss': stat.maxMiss,
          'frequency': stat.frequency,
          'recent_trend': stat.recentTrend,
          'hot_cold_status': stat.hotColdStatus,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
  
  /// 获取号码统计
  Future<List<NumberStatistics>> getNumberStatistics(String lotteryType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'number_statistics',
      where: 'lottery_type = ?',
      whereArgs: [lotteryType],
      orderBy: 'number ASC',
    );
    return maps.map((map) => NumberStatistics(
      number: map['number'],
      totalCount: map['total_count'],
      recent30Count: map['recent30_count'],
      recent50Count: map['recent50_count'],
      recent100Count: map['recent100_count'],
      currentMiss: map['current_miss'],
      avgMiss: map['avg_miss'].toDouble(),
      maxMiss: map['max_miss'],
      frequency: map['frequency'].toDouble(),
      recentTrend: map['recent_trend'].toDouble(),
      hotColdStatus: map['hot_cold_status'],
    )).toList();
  }
  
  // ==================== 预测记录操作 ====================
  
  /// 保存预测
  Future<void> savePrediction(Prediction prediction) async {
    final db = await database;
    await db.insert(
      'predictions',
      {
        'id': prediction.id,
        'lottery_type': prediction.lotteryType.code,
        'front_numbers': prediction.frontNumbers.join(','),
        'back_numbers': prediction.backNumbers.join(','),
        'confidence': prediction.confidence,
        'strategy': prediction.strategy,
        'explanation': prediction.explanation,
        'created_at': prediction.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 获取历史预测
  Future<List<Prediction>> getPredictions(LotteryType type, {int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'predictions',
      where: 'lottery_type = ?',
      whereArgs: [type.code],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => Prediction(
      id: map['id'],
      lotteryType: type,
      frontNumbers: (map['front_numbers'] as String).split(',').map(int.parse).toList(),
      backNumbers: map['back_numbers'] != null && (map['back_numbers'] as String).isNotEmpty
          ? (map['back_numbers'] as String).split(',').map(int.parse).toList()
          : [],
      confidence: map['confidence'],
      strategy: map['strategy'],
      explanation: map['explanation'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    )).toList();
  }
  
  // ==================== 回测结果操作 ====================
  
  /// 保存回测结果
  Future<void> saveBacktestResult(BacktestResult result, String lotteryType) async {
    final db = await database;
    await db.insert(
      'backtest_results',
      {
        'strategy': result.strategy,
        'lottery_type': lotteryType,
        'total_tests': result.totalTests,
        'hits0': result.hits0,
        'hits1': result.hits1,
        'hits2': result.hits2,
        'hits3': result.hits3,
        'hits4': result.hits4,
        'hits5': result.hits5,
        'hits6': result.hits6,
        'back_hits': result.backHits,
        'avg_hit_count': result.avgHitCount,
        'win_rate': result.winRate,
        'tested_at': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// 获取最新回测结果
  Future<BacktestResult?> getLatestBacktestResult(String strategy, String lotteryType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'backtest_results',
      where: 'strategy = ? AND lottery_type = ?',
      whereArgs: [strategy, lotteryType],
      orderBy: 'tested_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BacktestResult(
      strategy: maps.first['strategy'],
      totalTests: maps.first['total_tests'],
      hits0: maps.first['hits0'],
      hits1: maps.first['hits1'],
      hits2: maps.first['hits2'],
      hits3: maps.first['hits3'],
      hits4: maps.first['hits4'],
      hits5: maps.first['hits5'],
      hits6: maps.first['hits6'],
      backHits: maps.first['back_hits'],
      avgHitCount: maps.first['avg_hit_count'],
      winRate: maps.first['win_rate'],
    );
  }
  
  // ==================== 更新日志操作 ====================
  
  /// 更新数据同步日志
  Future<void> updateSyncLog(String lotteryType, String lastIssue, int count) async {
    final db = await database;
    await db.insert(
      'update_logs',
      {
        'lottery_type': lotteryType,
        'last_issue': lastIssue,
        'update_time': DateTime.now().toIso8601String(),
        'record_count': count,
      },
    );
  }
  
  /// 获取最近一次同步信息
  Future<Map<String, dynamic>?> getLatestSyncLog(String lotteryType) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'update_logs',
      where: 'lottery_type = ?',
      whereArgs: [lotteryType],
      orderBy: 'update_time DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }
  
  /// 清空所有数据
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('lottery_results');
    await db.delete('number_statistics');
    await db.delete('predictions');
    await db.delete('backtest_results');
    await db.delete('update_logs');
  }
}
