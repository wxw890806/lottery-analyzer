import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lottery_provider.dart';
import '../providers/prediction_provider.dart';
import '../models/lottery_models.dart';
import '../services/prediction_generator.dart';
import '../utils/app_theme.dart';
import '../widgets/lottery_ball.dart';

/// 预测结果页面
class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能预测'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _generatePrediction(context),
          ),
        ],
      ),
      body: Consumer<PredictionProvider>(
        builder: (context, provider, child) {
          if (provider.isPredicting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在分析数据...'),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // 策略选择
              _buildStrategySelector(context, provider),
              // 预测结果
              Expanded(
                child: provider.predictions.isEmpty
                    ? _buildEmptyState(context)
                    : _buildPredictionList(provider),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildStrategySelector(BuildContext context, PredictionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择预测策略',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PredictionGenerator.PredictionStrategy.values.map((strategy) {
                final isSelected = strategy == provider.currentStrategy;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_getStrategyName(strategy)),
                    selected: isSelected,
                    onSelected: (_) {
                      provider.setStrategy(strategy);
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.getStrategyDescription(provider.currentStrategy),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getStrategyName(PredictionGenerator.PredictionStrategy strategy) {
    switch (strategy) {
      case PredictionGenerator.PredictionStrategy.hot追踪:
        return '热号追踪';
      case PredictionGenerator.PredictionStrategy.cold反弹:
        return '冷号反弹';
      case PredictionGenerator.PredictionStrategy.balance平衡:
        return '区间平衡';
      case PredictionGenerator.PredictionStrategy.smart混合:
        return '智能混合';
    }
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            '点击右上角按钮生成预测',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _generatePrediction(context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('立即预测'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPredictionList(PredictionProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.predictions.length,
      itemBuilder: (context, index) {
        final prediction = provider.predictions[index];
        return _buildPredictionCard(prediction, index + 1, provider);
      },
    );
  }
  
  Widget _buildPredictionCard(Prediction prediction, int rank, PredictionProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            // 红球
            ...prediction.frontNumbers.map((num) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: LotteryBall(
                number: num,
                isRed: true,
                size: AppDimensions.ballSizeSmall,
              ),
            )),
            // 蓝球
            if (prediction.backNumbers.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...prediction.backNumbers.map((num) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: LotteryBall(
                  number: num,
                  isRed: false,
                  size: AppDimensions.ballSizeSmall,
                ),
              )),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              _buildConfidenceIndicator(prediction.confidence),
              const SizedBox(width: 8),
              Text(
                prediction.strategy,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        children: [
          // 置信度进度条
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('置信度', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${prediction.confidence.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: prediction.confidence / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getConfidenceColor(prediction.confidence),
                  ),
                ),
              ),
              const Divider(height: 24),
              // 分析说明
              const Text(
                '分析依据',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                prediction.explanation,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return AppTheme.primaryColor;
    }
  }
  
  Widget _buildConfidenceIndicator(double confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getConfidenceColor(confidence).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getConfidenceColor(confidence)),
      ),
      child: Text(
        '${confidence.toStringAsFixed(0)}分',
        style: TextStyle(
          color: _getConfidenceColor(confidence),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 70) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }
  
  Future<void> _generatePrediction(BuildContext context) async {
    final lotteryProvider = context.read<LotteryProvider>();
    final predictionProvider = context.read<PredictionProvider>();
    
    if (lotteryProvider.results.isEmpty) {
      await lotteryProvider.loadData();
    }
    
    predictionProvider.setHistoricalData(lotteryProvider.results);
    await predictionProvider.generatePredictions();
  }
}
