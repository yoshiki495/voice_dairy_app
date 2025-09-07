import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/emotion_analysis_service.dart';
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
  final EmotionAnalysisService _emotionService = EmotionAnalysisService();

  MoodNotifier() : super(const MoodState()) {
    loadMoodData();
  }

  Future<void> loadMoodData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 過去1ヶ月のデータを取得
      final now = DateTime.now();
      final monthAgo = DateTime(now.year, now.month - 1, now.day);
      
      final results = await _emotionService.getMoodData(
        startDate: monthAgo,
        endDate: now,
      );
      
      final entries = results.map((result) {
        final dateString = DateFormat('yyyy-MM-dd').format(result.timestamp);
        return MoodEntry(
          id: 'mood_${dateString}_${result.timestamp.millisecondsSinceEpoch}',
          date: dateString,
          score: result.score,
          label: MoodLabel.fromCategory(result.category),
          intensity: result.intensity,
          recordedAt: result.timestamp,
          storagePath: null, // 必要に応じて設定
          source: 'daily_20_jst',
          version: 2,
        );
      }).toList();
      
      // 日付順にソート
      entries.sort((a, b) => a.date.compareTo(b.date));
      
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      // エラー時はサンプルデータを使用
      print('感情データ取得エラー: $e');
      final entries = SampleDataService.generateMonthlyMoodData();
      state = state.copyWith(entries: entries, isLoading: false);
    }
  }

  /// 音声ファイルから感情分析を実行してエントリを追加
  Future<void> addMoodEntryFromAudio(String audioFilePath) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 感情分析を実行
      final result = await _emotionService.analyzeEmotion(
        audioFilePath: audioFilePath,
      );
      
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);
      
      final newEntry = MoodEntry(
        id: 'mood_${dateString}_${now.millisecondsSinceEpoch}',
        date: dateString,
        score: result.score,
        label: MoodLabel.fromCategory(result.category),
        intensity: result.intensity,
        recordedAt: result.timestamp,
        storagePath: null, // Firebase Functionsで管理
        source: 'daily_20_jst',
        version: 2,
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
        error: '感情分析に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// 旧バージョン互換のためのメソッド（テスト用）
  @Deprecated('Use addMoodEntryFromAudio instead')
  Future<void> addMoodEntry(double score) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);
      
      final newEntry = MoodEntry(
        id: 'mood_${dateString}_${now.millisecondsSinceEpoch}',
        date: dateString,
        score: double.parse(score.toStringAsFixed(2)),
        label: MoodLabel.fromScore(score),
        intensity: score, // 簡易実装
        recordedAt: now,
        storagePath: null,
        source: 'manual_test',
        version: 1,
      );

      final updatedEntries = state.entries
          .where((entry) => entry.date != dateString)
          .toList();
      
      updatedEntries.add(newEntry);
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
