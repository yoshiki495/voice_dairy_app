import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/sample_data_service.dart';

class MoodSummary extends StatelessWidget {
  final List<MoodEntry> entries;

  const MoodSummary({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final summary = SampleDataService.getWeeklySummary(entries);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今週のサマリー',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 平均スコア
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getScoreColor(summary['averageScore']),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '平均スコア: ${summary['averageScore'].toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 記録日数
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '記録日数: ${summary['totalEntries']}/7日',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 感情分布
          Text(
            '感情分布',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildMoodCount(
                  context,
                  'ポジティブ',
                  summary['positiveCount'],
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMoodCount(
                  context,
                  '普通',
                  summary['neutralCount'],
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMoodCount(
                  context,
                  'ネガティブ',
                  summary['negativeCount'],
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCount(BuildContext context, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.1) return Colors.green;
    if (score <= -0.1) return Colors.red;
    return Colors.orange;
  }
}
