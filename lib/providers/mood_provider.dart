import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_entry.dart';
import '../services/emotion_analysis_service.dart';
import '../services/sample_data_service.dart';
import '../services/emotion_dynamics_service.dart';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // Firestoreからすべてのデータを取得
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .get();
      
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        final dateString = doc.id; // ドキュメントIDが日付文字列（yyyy-MM-dd）
        
        // recordedAtがTimestampの場合とStringの場合に対応
        DateTime recordedAt;
        if (data['recordedAt'] is Timestamp) {
          recordedAt = (data['recordedAt'] as Timestamp).toDate();
        } else if (data['recordedAt'] is String) {
          recordedAt = DateTime.parse(data['recordedAt'] as String);
        } else {
          // フォールバック: 日付文字列から20:00 JSTを作成
          final dateParts = dateString.split('-');
          recordedAt = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
            20,
            0,
          );
        }
        
        final score = (data['score'] as num).toDouble();
        final category = data['category'] as String? ?? 'neutral';
        
        return MoodEntry(
          id: doc.id,
          date: dateString,
          score: score,
          label: MoodLabel.fromCategory(category),
          intensity: (data['intensity'] as num?)?.toDouble() ?? score.abs(),
          recordedAt: recordedAt,
          storagePath: data['storagePath'] as String?,
          source: data['source'] as String? ?? 'unknown',
          version: data['version'] as int? ?? 1,
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
        storagePath: null, // Cloud Run APIで管理
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

  /// ベースライン期間のエントリを取得（最初の7日間）
  List<MoodEntry> getBaselinePeriodEntries() {
    if (state.entries.isEmpty) {
      return [];
    }
    
    // 日付でソート（古い順）
    final sortedEntries = List<MoodEntry>.from(state.entries)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // 最初の7日分を取得
    return sortedEntries.take(7).toList();
  }

  /// 介入期間のエントリを取得（直近7日間）
  List<MoodEntry> getInterventionPeriodEntries() {
    return getWeeklyEntries();
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

// 感情ダイナミクスフィードバックを提供するプロバイダー
final emotionDynamicsFeedbackProvider = Provider<Map<String, dynamic>?>((ref) {
  final moodState = ref.watch(moodProvider); // 状態の変更を監視
  final moodNotifier = ref.read(moodProvider.notifier);
  
  // 全エントリのユニークな日数をチェック
  final allEntries = moodState.entries;
  final uniqueDates = allEntries.map((e) => e.date).toSet();
  
  // 最低8日分のユニークなデータが必要（ベースラインと介入期間が重複しないため）
  if (uniqueDates.length < 8) {
    return null;
  }
  
  final baselineEntries = moodNotifier.getBaselinePeriodEntries();
  final interventionEntries = moodNotifier.getInterventionPeriodEntries();
  
  // 各期間に最低7日分のデータが必要
  if (baselineEntries.length < 7 || interventionEntries.length < 7) {
    return null;
  }
  
  // 各期間の感情ダイナミクスを計算
  final baselineResult = EmotionDynamicsService.calculate(baselineEntries);
  final interventionResult = EmotionDynamicsService.calculate(interventionEntries);
  
  if (baselineResult == null || interventionResult == null) {
    return null;
  }
  
  // パターンを判定
  final patternId = EmotionDynamicsService.determinePattern(
    baselineResult,
    interventionResult,
  );
  
  // フィードバックを取得
  final feedback = EmotionDynamicsService.getFeedbackByPattern(patternId);
  
  return {
    'patternId': patternId,
    'pattern': feedback['pattern'],
    'interpretation': feedback['interpretation'],
    'nextStep': feedback['nextStep'],
    'baselineData': {
      'variability': baselineResult.variability,
      'instability': baselineResult.instability,
      'inertia': baselineResult.inertia,
    },
    'interventionData': {
      'variability': interventionResult.variability,
      'instability': interventionResult.instability,
      'inertia': interventionResult.inertia,
    },
  };
});
