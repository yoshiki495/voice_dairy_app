import 'dart:math';
import '../models/mood_entry.dart';

/// 感情ダイナミクスの分析結果
class EmotionDynamicsResult {
  /// 感情変動性 (Emotional Variability) - iSD
  final double variability;
  
  /// 感情不安定性 (Emotional Instability) - MSSD
  final double instability;
  
  /// 感情慣性 (Emotional Inertia) - Autocorrelation
  final double inertia;
  
  /// 平均感情スコア
  final double averageScore;
  
  /// データポイント数
  final int dataPoints;

  const EmotionDynamicsResult({
    required this.variability,
    required this.instability,
    required this.inertia,
    required this.averageScore,
    required this.dataPoints,
  });

  /// 感情が安定しているかどうか
  bool get isStable => variability < 0.3 && instability < 0.2;
  
  /// 感情が一定に保たれているか
  bool get isConsistent => inertia > 0.5;
  
  /// 全体的な感情傾向
  String get overallTrend {
    if (averageScore > 0.3) return 'positive';
    if (averageScore < -0.3) return 'negative';
    return 'neutral';
  }
}

/// 感情ダイナミクスを計算するサービス
class EmotionDynamicsService {
  /// 感情ダイナミクスを計算
  /// 
  /// [entries] 分析対象の感情エントリーリスト（時系列順）
  /// 最低2つのデータポイントが必要
  static EmotionDynamicsResult? calculate(List<MoodEntry> entries) {
    if (entries.length < 2) {
      return null; // 最低2つのデータポイントが必要
    }

    // 日付でソート（古い順）
    final sortedEntries = List<MoodEntry>.from(entries)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final scores = sortedEntries.map((e) => e.score).toList();
    
    // 平均スコアを計算
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    
    // 感情変動性 (iSD) を計算
    final variability = _calculateVariability(scores, mean);
    
    // 感情不安定性 (MSSD) を計算
    final instability = _calculateInstability(scores);
    
    // 感情慣性 (Autocorrelation) を計算
    final inertia = _calculateInertia(scores, mean);

    return EmotionDynamicsResult(
      variability: variability,
      instability: instability,
      inertia: inertia,
      averageScore: mean,
      dataPoints: scores.length,
    );
  }

  /// 感情変動性 (Emotional Variability) を計算
  /// 計算式: SD = √[Σ(xi - x̄)² / N]
  static double _calculateVariability(List<double> scores, double mean) {
    if (scores.isEmpty) return 0.0;
    
    final sumSquaredDiff = scores.fold<double>(
      0.0,
      (sum, score) => sum + pow(score - mean, 2),
    );
    
    return sqrt(sumSquaredDiff / scores.length);
  }

  /// 感情不安定性 (Emotional Instability) を計算
  /// 計算式: MSSD = Σ(xi+1 - xi)² / (N - 1)
  static double _calculateInstability(List<double> scores) {
    if (scores.length < 2) return 0.0;
    
    double sumSquaredDiff = 0.0;
    for (int i = 0; i < scores.length - 1; i++) {
      final diff = scores[i + 1] - scores[i];
      sumSquaredDiff += diff * diff;
    }
    
    return sumSquaredDiff / (scores.length - 1);
  }

  /// 感情慣性 (Emotional Inertia) を計算
  /// 計算式: r1 = Σ[(xi - x̄)(xi+1 - x̄)] / Σ(xi - x̄)²
  static double _calculateInertia(List<double> scores, double mean) {
    if (scores.length < 2) return 0.0;
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < scores.length - 1; i++) {
      numerator += (scores[i] - mean) * (scores[i + 1] - mean);
    }
    
    for (int i = 0; i < scores.length; i++) {
      denominator += pow(scores[i] - mean, 2);
    }
    
    if (denominator == 0) return 0.0;
    
    return numerator / denominator;
  }

  /// フィードバックメッセージを生成
  static String generatePatternFeedback(EmotionDynamicsResult result) {
    if (result.isStable) {
      if (result.overallTrend == 'positive') {
        return '今週は感情の変動が少なく安定していました。気分の波が穏やかで一定のリズムを保っています。';
      } else if (result.overallTrend == 'negative') {
        return '今週は感情の変動が少なく安定していましたが、全体的にネガティブな傾向が見られます。';
      } else {
        return '今週は感情の変動が少なく安定していました。気分の波が穏やかで一定のリズムを保っています。';
      }
    } else {
      if (result.variability > 0.5) {
        return '今週は感情の変動が大きく、気分の波が激しい状態でした。';
      } else {
        return '今週は感情の変動がやや見られましたが、概ね安定した状態を保っています。';
      }
    }
  }

  /// 安定性に関するフィードバックメッセージを生成
  static String generateStabilityFeedback(EmotionDynamicsResult result) {
    if (result.isStable && result.isConsistent) {
      return '感情が一定に保たれていることは、多くの場合良い兆候です。これは感情調節が上手くできている証拠かもしれません。';
    } else if (!result.isStable && result.instability > 0.3) {
      return '感情の変化が急激に起こることが多いようです。ストレスや疲労が原因の可能性があります。';
    } else if (result.isConsistent && result.inertia > 0.7) {
      return '感情が持続しやすい傾向があります。ネガティブな感情の場合は、気分転換を心がけましょう。';
    } else {
      return '感情のバランスは概ね良好です。このまま自分のペースを大切にしていきましょう。';
    }
  }

  /// 次のステップの推奨を生成
  static List<String> generateRecommendations(EmotionDynamicsResult result) {
    final recommendations = <String>[];

    if (result.isStable && result.overallTrend == 'positive') {
      recommendations.add('5分間の呼吸エクササイズを試す');
      recommendations.add('感謝の気持ちを日記に書く');
    } else if (result.isStable && result.overallTrend == 'neutral') {
      recommendations.add('5分間の呼吸エクササイズを試す');
      recommendations.add('軽い運動やストレッチをする');
    } else if (!result.isStable) {
      recommendations.add('マインドフルネス瞑想を実践する');
      recommendations.add('十分な睡眠時間を確保する');
      recommendations.add('信頼できる人と話す時間を作る');
    } else if (result.overallTrend == 'negative') {
      recommendations.add('好きな音楽を聴いてリラックスする');
      recommendations.add('自然の中で散歩をする');
      recommendations.add('専門家に相談することを検討する');
    } else {
      recommendations.add('5分間の呼吸エクササイズを試す');
      recommendations.add('好きな趣味の時間を作る');
    }

    return recommendations;
  }
}

