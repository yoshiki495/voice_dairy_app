import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mood_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(emotionDynamicsFeedbackProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(moodProvider.notifier).loadMoodData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // フィードバックセクション
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: feedback == null
                  ? _buildNoDataMessage(context)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 今週の感情パターン
                        _buildFeedbackCard(
                          context: context,
                          title: '今週の感情パターン',
                          content: feedback['pattern'] as String,
                          icon: Icons.trending_up,
                        ),
                        const SizedBox(height: 16),

                        // 感情の安定性について
                        _buildFeedbackCard(
                          context: context,
                          title: '感情の安定性について',
                          content: feedback['interpretation'] as String,
                          icon: Icons.psychology,
                        ),
                        const SizedBox(height: 16),

                        // 次のステップ
                        _buildNextStepsCard(
                          context: context,
                          nextStep: feedback['nextStep'] as String,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
                    Text(
                      'フィードバックを表示するには\n8日分以上のデータが必要です',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
            const SizedBox(height: 8),
            Text(
              '毎日の記録を続けることで、\n感情パターンの分析結果が表示されます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepsCard({
    required BuildContext context,
    required String nextStep,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '次のステップ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              nextStep,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
