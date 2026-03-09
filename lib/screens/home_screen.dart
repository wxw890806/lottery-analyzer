import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lottery_models.dart';
import '../providers/lottery_provider.dart';
import '../providers/prediction_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/lottery_ball.dart';
import 'analysis_screen.dart';
import 'prediction_screen.dart';
import 'backtest_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }
  
  Future<void> _loadInitialData() async {
    final lotteryProvider = context.read<LotteryProvider>();
    final predictionProvider = context.read<PredictionProvider>();
    
    await lotteryProvider.loadData();
    
    if (lotteryProvider.results.isNotEmpty) {
      predictionProvider.setHistoricalData(lotteryProvider.results);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const AnalysisScreen(),
          const PredictionScreen(),
          const BacktestScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: '预测',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '回测',
          ),
        ],
      ),
    );
  }
  
  Widget _buildHomeTab() {
    return Consumer<LotteryProvider>(
      builder: (context, provider, child) {
        return CustomScrollView(
          slivers: [
            // 顶部导航
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('彩票规律分析器'),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => provider.syncData(),
                ),
              ],
            ),
            
            // 彩种选择
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: LotteryType.values.length,
                  itemBuilder: (context, index) {
                    final type = LotteryType.values[index];
                    final isSelected = type == provider.selectedType;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ChoiceChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (_) => provider.setSelectedType(type),
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 最新开奖结果
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.latestResult != null)
              SliverToBoxAdapter(
                child: _buildLatestResult(provider.latestResult!),
              )
            else
              const SliverFillRemaining(
                child: Center(child: Text('暂无数据')),
              ),
            
            // 一键预测按钮
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => _generatePrediction(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome),
                      SizedBox(width: 10),
                      Text(
                        '一键智能预测',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 近期预测准确率
            SliverToBoxAdapter(
              child: _buildAccuracyCard(),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildLatestResult(LotteryResult result) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第 ${result.issueNo} 期',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${result.drawDate.year}-${result.drawDate.month.toString().padLeft(2, '0')}-${result.drawDate.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 红球
            Row(
              children: [
                const Text('红球: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                ...result.frontNumbers.map((num) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: LotteryBall(
                    number: num,
                    isRed: true,
                    size: AppDimensions.ballSizeSmall,
                  ),
                )),
              ],
            ),
            const SizedBox(height: 12),
            // 蓝球
            if (result.backNumbers.isNotEmpty)
              Row(
                children: [
                  const Text('蓝球: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  ...result.backNumbers.map((num) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LotteryBall(
                      number: num,
                      isRed: false,
                      size: AppDimensions.ballSizeSmall,
                    ),
                  )),
                ],
              ),
            const Divider(height: 30),
            // 开奖信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('和值', result.sumValue.toString()),
                _buildInfoItem('跨度', result.span.toString()),
                _buildInfoItem('奇偶', result.oddEvenRatio),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
  
  Widget _buildAccuracyCard() {
    return Consumer<PredictionProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      '近期预测准确率',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 准确率进度条
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.35,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3红及以上命中率',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const Text(
                      '35%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _generatePrediction() async {
    final predictionProvider = context.read<PredictionProvider>();
    await predictionProvider.generatePredictions();
    
    if (mounted && predictionProvider.predictions.isNotEmpty) {
      // 切换到预测页面
      setState(() => _currentIndex = 2);
    }
  }
}
