import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/mood_chart.dart';
import '../../widgets/mood_summary.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodState = ref.watch(moodProvider);
    final weeklyEntries = ref.watch(weeklyMoodProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(moodProvider.notifier).loadMoodData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 週次グラフセクション
            if (moodState.isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (moodState.error != null) ...[
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        moodState.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(moodProvider.notifier).loadMoodData();
                        },
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // グラフ表示
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: MoodChart(entries: weeklyEntries),
                ),
                
                const SizedBox(height: 16),
                
                // サマリー表示
                MoodSummary(entries: weeklyEntries),
              ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
