import 'dart:math';
import '../models/user.dart';
import '../models/mood_entry.dart';

class SampleDataService {
  static final Random _random = Random();

  // サンプルユーザー
  static User get sampleUser => User(
    id: 'sample_user_123',
    email: 'sample@example.com',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  // 過去1週間のサンプル感情データを生成
  static List<MoodEntry> generateWeeklyMoodData() {
    final List<MoodEntry> entries = [];
    final now = DateTime.now();
    
    // 過去7日分のデータを生成
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // ランダムなスコアを生成（-1.0 から 1.0）
      final score = (_random.nextDouble() * 2.0) - 1.0;
      final label = MoodLabel.fromScore(score);
      
      final entry = MoodEntry(
        id: 'mood_${dateString}_${_random.nextInt(1000)}',
        date: dateString,
        score: double.parse(score.toStringAsFixed(2)),
        label: label,
        recordedAt: DateTime(
          date.year,
          date.month,
          date.day,
          20, // 20:00 JST
          _random.nextInt(60), // ランダムな分
        ),
        gcsUri: 'gs://sample-bucket/audio/sample_user_123/$dateString.m4a',
        source: 'daily_20_jst',
        version: 1,
      );
      
      entries.add(entry);
    }
    
    return entries;
  }

  // 過去1ヶ月のサンプル感情データを生成
  static List<MoodEntry> generateMonthlyMoodData() {
    final List<MoodEntry> entries = [];
    final now = DateTime.now();
    
    // 過去30日分のデータを生成（一部欠損させてリアルさを演出）
    for (int i = 29; i >= 0; i--) {
      // 20%の確率でデータを欠損させる
      if (_random.nextDouble() < 0.2) continue;
      
      final date = now.subtract(Duration(days: i));
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // より自然な分布のスコアを生成
      double score;
      final rand = _random.nextDouble();
      if (rand < 0.3) {
        // 30%の確率でポジティブ（0.3〜1.0）
        score = 0.3 + (_random.nextDouble() * 0.7);
      } else if (rand < 0.6) {
        // 30%の確率でニュートラル（-0.3〜0.3）
        score = (_random.nextDouble() * 0.6) - 0.3;
      } else {
        // 40%の確率でネガティブ（-1.0〜-0.3）
        score = -1.0 + (_random.nextDouble() * 0.7);
      }
      
      final label = MoodLabel.fromScore(score);
      
      final entry = MoodEntry(
        id: 'mood_${dateString}_${_random.nextInt(1000)}',
        date: dateString,
        score: double.parse(score.toStringAsFixed(2)),
        label: label,
        recordedAt: DateTime(
          date.year,
          date.month,
          date.day,
          20, // 20:00 JST
          _random.nextInt(60), // ランダムな分
        ),
        gcsUri: 'gs://sample-bucket/audio/sample_user_123/$dateString.m4a',
        source: 'daily_20_jst',
        version: 1,
      );
      
      entries.add(entry);
    }
    
    return entries;
  }

  // 今日のデータが存在するかチェック
  static bool hasTodayData(List<MoodEntry> entries) {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    return entries.any((entry) => entry.date == todayString);
  }

  // 週次データのサマリーを取得
  static Map<String, dynamic> getWeeklySummary(List<MoodEntry> entries) {
    if (entries.isEmpty) {
      return {
        'averageScore': 0.0,
        'totalEntries': 0,
        'positiveCount': 0,
        'neutralCount': 0,
        'negativeCount': 0,
      };
    }

    final totalScore = entries.fold<double>(0.0, (sum, entry) => sum + entry.score);
    final averageScore = totalScore / entries.length;

    int positiveCount = 0;
    int neutralCount = 0;
    int negativeCount = 0;

    for (final entry in entries) {
      switch (entry.label) {
        case MoodLabel.positive:
          positiveCount++;
          break;
        case MoodLabel.neutral:
          neutralCount++;
          break;
        case MoodLabel.negative:
          negativeCount++;
          break;
      }
    }

    return {
      'averageScore': double.parse(averageScore.toStringAsFixed(2)),
      'totalEntries': entries.length,
      'positiveCount': positiveCount,
      'neutralCount': neutralCount,
      'negativeCount': negativeCount,
    };
  }
}
