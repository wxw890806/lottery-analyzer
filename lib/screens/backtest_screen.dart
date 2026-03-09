import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/lottery_provider.dart';
import '../providers/prediction_provider.dart';
import '../services/prediction_generator.dart';
import '../utils/app_theme.dart';

/// 回测验证页面
class BacktestScreen extends StatelessWidget {
  const BacktestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回测验证'),
      ),
      body: Consumer<PredictionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 回测说明
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              '回测说明',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '使用历史数据验证预测策略的有效性。'
                          '系统会使用前N期数据作为训练集，预测第N+1期，并与实际开奖结果对比。',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 参数设置
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '参数设置',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '训练集大小',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('100期', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '测试集大小',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('30期', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 开始回测按钮
                ElevatedButton.icon(
                  onPressed: provider.isBacktesting
                      ? null
                      : () => _runBacktest(context),
                  icon: provider.isBacktesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(provider.isBacktesting ? '回测中...' : '开始回测'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 回测结果
                if (provider.backtestResult != null)
                  _buildBacktestResult(provider),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildBacktestResult(PredictionProvider provider) {
    final result = provider.backtestResult!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '回测结果',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // 统计概览
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '总测试期数',
                result.totalTests.toString(),
                Icons.timeline,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '平均命中',
                result.avgHitCount.toStringAsFixed(2) + '个',
                Icons.analytics,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '中奖率(3红+)',
                '${(result.winRate * 100).toStringAsFixed(1)}%',
                Icons.emoji_events,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '蓝球命中率',
                '${(result.backHits / result.totalTests * 100).toStringAsFixed(1)}%',
                Icons.circle,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // 命中分布图表
        const Text(
          '命中分布',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: result.totalTests.toDouble(),
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const titles = ['0红', '1红', '2红', '3红', '4红', '5红', '6红'];
                      return Text(
                        titles[value.toInt()],
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: [
                _makeBarGroup(0, result.hits0.toDouble(), Colors.grey),
                _makeBarGroup(1, result.hits1.toDouble(), Colors.grey.shade300),
                _makeBarGroup(2, result.hits2.toDouble(), Colors.yellow.shade600),
                _makeBarGroup(3, result.hits3.toDouble(), Colors.orange),
                _makeBarGroup(4, result.hits4.toDouble(), Colors.deepOrange),
                _makeBarGroup(5, result.hits5.toDouble(), Colors.red),
                _makeBarGroup(6, result.hits6.toDouble(), Colors.red.shade900),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // 详细统计
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '详细统计',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('命中0个', result.hits0),
                _buildDetailRow('命中1个', result.hits1),
                _buildDetailRow('命中2个', result.hits2),
                _buildDetailRow('命中3个 (五等奖)', result.hits3),
                _buildDetailRow('命中4个 (四等奖)', result.hits4),
                _buildDetailRow('命中5个 (三等奖)', result.hits5),
                _buildDetailRow('命中6个 (二等奖/一等奖)', result.hits6),
                _buildDetailRow('命中蓝球', result.backHits),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 策略评估
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '策略评估',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildEvaluation(result),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEvaluation(dynamic result) {
    String evaluation;
    Color color;
    
    if (result.winRate > 0.4) {
      evaluation = '表现优秀！该策略在历史数据上表现良好，值得期待。';
      color = Colors.green;
    } else if (result.winRate > 0.2) {
      evaluation = '表现良好。该策略在历史数据上达到正常水平。';
      color = Colors.orange;
    } else {
      evaluation = '表现一般。建议尝试其他预测策略以获得更好效果。';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            result.winRate > 0.2 ? Icons.thumb_up : Icons.thumb_down,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              evaluation,
              style: TextStyle(color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _runBacktest(BuildContext context) async {
    final lotteryProvider = context.read<LotteryProvider>();
    final predictionProvider = context.read<PredictionProvider>();
    
    if (lotteryProvider.results.isEmpty) {
      await lotteryProvider.loadData();
    }
    
    predictionProvider.setHistoricalData(lotteryProvider.results);
    await predictionProvider.runBacktest();
  }
}
