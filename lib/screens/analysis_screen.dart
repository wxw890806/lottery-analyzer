import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/lottery_provider.dart';
import '../providers/analysis_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/lottery_ball.dart';

/// 数据分析页面
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeData();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _analyzeData() {
    final lotteryProvider = context.read<LotteryProvider>();
    final analysisProvider = context.read<AnalysisProvider>();
    
    if (lotteryProvider.results.isNotEmpty) {
      analysisProvider.setHistoricalData(lotteryProvider.results);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '频率分析'),
            Tab(text: '遗漏分析'),
            Tab(text: '趋势图'),
          ],
        ),
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isAnalyzing) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildFrequencyTab(provider),
              _buildMissTab(provider),
              _buildTrendTab(provider),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildFrequencyTab(AnalysisProvider provider) {
    final stats = provider.frontNumberStats;
    if (stats == null || stats.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    
    // 按频率排序
    final sortedStats = List.from(stats)
      ..sort((a, b) => b.recent30Count.compareTo(a.recent30Count));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 热力图
          const Text(
            '号码频率热力图（近30期）',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildHeatMap(stats),
          const SizedBox(height: 24),
          // Top 10 热号
          const Text(
            '热门号码 Top 10',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...sortedStats.take(10).map((s) => _buildFrequencyItem(s, true)),
          const SizedBox(height: 24),
          // Top 10 冷号
          final coldStats = List.from(stats)
            ..sort((a, b) => a.recent30Count.compareTo(b.recent30Count));
          const Text(
            '冷门号码 Top 10',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...coldStats.take(10).map((s) => _buildFrequencyItem(s, false)),
        ],
      ),
    );
  }
  
  Widget _buildHeatMap(List stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 11,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        final intensity = s.recent30Count / 10;
        return Container(
          decoration: BoxDecoration(
            color: _getHeatColor(intensity),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              s.number.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 10,
                color: intensity > 0.5 ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Color _getHeatColor(double ratio) {
    if (ratio > 0.8) return Colors.red.shade700;
    if (ratio > 0.6) return Colors.orange;
    if (ratio > 0.4) return Colors.yellow.shade600;
    if (ratio > 0.2) return Colors.lightGreen;
    return Colors.green.shade100;
  }
  
  Widget _buildFrequencyItem(dynamic stat, bool isHot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: LotteryBall(
          number: stat.number,
          isRed: true,
          size: 36,
        ),
        title: Text('号码 ${stat.number.toString().padLeft(2, '0')}'),
        subtitle: Text('近30期: ${stat.recent30Count}次 | 总体: ${stat.totalCount}次'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isHot ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isHot ? '热' : '冷',
            style: TextStyle(
              color: isHot ? Colors.red : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMissTab(AnalysisProvider provider) {
    final missRanking = provider.getMissRanking();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '当前遗漏值排行',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...missRanking.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: LotteryBall(
                number: s.number,
                isRed: true,
                size: 36,
              ),
              title: Text('号码 ${s.number.toString().padLeft(2, '0')}'),
              subtitle: Text(
                '当前遗漏: ${s.currentMiss}期 | 平均遗漏: ${s.avgMiss.toStringAsFixed(1)}期 | 最大遗漏: ${s.maxMiss}期',
              ),
              trailing: _buildMissIndicator(s),
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildMissIndicator(dynamic stat) {
    final ratio = stat.currentMiss / stat.maxMiss;
    Color color;
    String text;
    
    if (ratio > 0.8) {
      color = Colors.red;
      text = '极冷';
    } else if (ratio > 0.5) {
      color = Colors.orange;
      text = '较冷';
    } else if (ratio < 0.2) {
      color = Colors.green;
      text = '温';
    } else {
      color = Colors.blue;
      text = '正常';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
  
  Widget _buildTrendTab(AnalysisProvider provider) {
    final stats = provider.frontNumberStats;
    if (stats == null || stats.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    
    // 选择前10个高频号码展示趋势
    final topNumbers = List.from(stats)
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));
    final selectedNumbers = topNumbers.take(8).map((s) => s.number).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '热门号码出现趋势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: selectedNumbers.asMap().entries.map((entry) {
                  final colors = [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                  ];
                  
                  return LineChartBarData(
                    spots: _generateTrendSpots(entry.value),
                    isCurved: true,
                    color: colors[entry.key % colors.length],
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 图例
          Wrap(
            spacing: 10,
            children: selectedNumbers.asMap().entries.map((e) {
              return Chip(
                label: Text(
                  e.value.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.grey.shade200,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  List<FlSpot> _generateTrendSpots(int number) {
    // 模拟趋势数据
    return List.generate(20, (i) {
      final value = 5 + (number % 10) * 0.3 + (i * 0.2) + (number % 3) * 0.5;
      return FlSpot(i.toDouble(), value);
    });
  }
}
