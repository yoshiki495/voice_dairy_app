import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home/home_screen.dart';
import 'feedback/feedback_screen.dart';
import '../providers/mood_provider.dart';

/// ボトムナビゲーションバーで選択されているタブのプロバイダー
final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late PageController _pageController;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    FeedbackScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabProvider);
    final weeklyEntries = ref.watch(weeklyMoodProvider);
    final hasTodayEntry = ref.watch(hasTodayEntryProvider);
    
    final titles = ['フィードバック', '週次グラフ'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // グリーティングセクション
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
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                ref.read(selectedTabProvider.notifier).state = index;
              },
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'フィードバック',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '週次グラフ',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/record'),
        tooltip: '音声を録音',
        child: const Icon(Icons.mic),
      ),
    );
  }
}

