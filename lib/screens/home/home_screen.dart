import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/mood_chart.dart';
import '../../widgets/mood_summary.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final moodState = ref.watch(moodProvider);
    final weeklyEntries = ref.watch(weeklyMoodProvider);
    final hasTodayEntry = ref.watch(hasTodayEntryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音声日記'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(moodProvider.notifier).loadMoodData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ユーザー情報とグリーティング
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'こんにちは！',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 今日の録音状況
                    if (!hasTodayEntry) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mic, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '今日の音声日記をまだ記録していません',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/record'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                              child: const Text('録音する'),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  '今日の音声日記を記録済みです',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            // 今日のエントリがある場合、詳細を表示
                            if (weeklyEntries.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Builder(
                                builder: (context) {
                                  final today = DateTime.now();
                                  final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                  final todayEntry = weeklyEntries.where((e) => e.date == todayString).firstOrNull;
                                  
                                  if (todayEntry != null) {
                                    return Row(
                                      children: [
                                        Icon(
                                          todayEntry.label.iconData,
                                          color: Colors.white.withOpacity(0.9),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${todayEntry.label.displayName} (${todayEntry.score.toStringAsFixed(1)})',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 週次グラフセクション
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '今週の感情グラフ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

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

              const SizedBox(height: 16),

              // アクションボタン
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/record'),
                        icon: const Icon(Icons.mic),
                        label: Text(hasTodayEntry ? '再録音' : '録音開始'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 過去のデータを表示（将来実装）
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('過去のデータ表示機能は今後実装予定です'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('履歴'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/record'),
        tooltip: '音声を録音',
        child: const Icon(Icons.mic),
      ),
    );
  }
}
