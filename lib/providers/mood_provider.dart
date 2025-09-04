import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mood_entry.dart';
import '../services/sample_data_service.dart';

// 感情データを管理するプロバイダー（サンプル実装）
class MoodState {
  final List<MoodEntry> entries;
  final bool isLoading;
  final String? error;

  const MoodState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  MoodState copyWith({
    List<MoodEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return MoodState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(const MoodState()) {
    loadMoodData();
  }

  Future<void> loadMoodData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 実際の実装では Firestore からデータを取得
      await Future.delayed(const Duration(milliseconds: 800));
      
      // サンプルデータを使用
      final entries = SampleDataService.generateMonthlyMoodData();
      
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'データの読み込みに失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> addMoodEntry(double score) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 実際の実装では音声録音・解析・Firestore保存を行う
      await Future.delayed(const Duration(seconds: 2));
      
      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final newEntry = MoodEntry(
        id: 'mood_${dateString}_${DateTime.now().millisecondsSinceEpoch}',
        date: dateString,
        score: double.parse(score.toStringAsFixed(2)),
        label: MoodLabel.fromScore(score),
        recordedAt: now,
        gcsUri: 'gs://sample-bucket/audio/sample_user_123/$dateString.m4a',
        source: 'daily_20_jst',
        version: 1,
      );

      // 既存のエントリから今日のデータを削除（あれば）
      final updatedEntries = state.entries
          .where((entry) => entry.date != dateString)
          .toList();
      
      // 新しいエントリを追加
      updatedEntries.add(newEntry);
      
      // 日付順にソート
      updatedEntries.sort((a, b) => a.date.compareTo(b.date));

      state = state.copyWith(entries: updatedEntries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: '感情記録の保存に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  List<MoodEntry> getWeeklyEntries() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    
    return state.entries.where((entry) {
      final entryDate = DateTime.parse('${entry.date}T00:00:00');
      return entryDate.isAfter(weekAgo.subtract(const Duration(days: 1))) &&
             entryDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  bool get hasTodayEntry {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return state.entries.any((entry) => entry.date == todayString);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier();
});

// 週次データを取得するプロバイダー
final weeklyMoodProvider = Provider<List<MoodEntry>>((ref) {
  ref.watch(moodProvider); // 状態の変更を監視
  final moodNotifier = ref.read(moodProvider.notifier);
  return moodNotifier.getWeeklyEntries();
});

// 今日のデータがあるかチェックするプロバイダー
final hasTodayEntryProvider = Provider<bool>((ref) {
  ref.watch(moodProvider); // 状態の変更を監視
  final moodNotifier = ref.read(moodProvider.notifier);
  return moodNotifier.hasTodayEntry;
});
