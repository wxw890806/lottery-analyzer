import 'package:flutter/material.dart';

/// 彩票球组件
class LotteryBall extends StatelessWidget {
  final int number;
  final bool isRed;
  final double size;
  final bool showBorder;
  
  const LotteryBall({
    super.key,
    required this.number,
    this.isRed = true,
    this.size = 44,
    this.showBorder = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRed
              ? [
                  const Color(0xFFFF6B6B),
                  const Color(0xFFE53935),
                  const Color(0xFFB71C1C),
                ]
              : [
                  const Color(0xFF64B5F6),
                  const Color(0xFF1976D2),
                  const Color(0xFF0D47A1),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isRed ? Colors.red : Colors.blue).withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: showBorder
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          number.toString().padLeft(2, '0'),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 球型展示容器
class BallContainer extends StatelessWidget {
  final List<int> numbers;
  final bool isRed;
  final double ballSize;
  final double spacing;
  
  const BallContainer({
    super.key,
    required this.numbers,
    this.isRed = true,
    this.ballSize = 44,
    this.spacing = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: numbers.map((num) => LotteryBall(
        number: num,
        isRed: isRed,
        size: ballSize,
      )).toList(),
    );
  }
}

/// 预测结果球展示（模拟真实彩票样式）
class LotteryBallDisplay extends StatelessWidget {
  final List<int> frontNumbers;
  final List<int> backNumbers;
  final double confidence;
  final String strategy;
  
  const LotteryBallDisplay({
    super.key,
    required this.frontNumbers,
    required this.backNumbers,
    required this.confidence,
    required this.strategy,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 策略标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStrategyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStrategyColor()),
            ),
            child: Text(
              strategy,
              style: TextStyle(
                color: _getStrategyColor(),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 红球
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: frontNumbers.map((num) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: LotteryBall(
                number: num,
                isRed: true,
                size: 40,
                showBorder: true,
              ),
            )).toList(),
          ),
          // 蓝球
          if (backNumbers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: backNumbers.map((num) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LotteryBall(
                  number: num,
                  isRed: false,
                  size: 40,
                  showBorder: true,
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          // 置信度
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('置信度: '),
              Text(
                '${confidence.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getConfidenceColor(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getStrategyColor() {
    switch (strategy) {
      case '热号追踪':
        return Colors.red;
      case '冷号反弹':
        return Colors.blue;
      case '区间平衡':
        return Colors.green;
      case '智能混合':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  Color _getConfidenceColor() {
    if (confidence >= 70) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }
}
