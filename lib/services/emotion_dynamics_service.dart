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

  /// ベースライン期間と介入期間を比較してパターンを判定
  /// 
  /// [baselineResult] ベースライン期間（7日前〜14日前）の感情ダイナミクス
  /// [interventionResult] 介入期間（直近7日間）の感情ダイナミクス
  /// 返り値: パターンID (例: "A-1", "B-5", "C-9")
  static String determinePattern(
    EmotionDynamicsResult baselineResult,
    EmotionDynamicsResult interventionResult,
  ) {
    // 閾値（変化率10%以上で変化ありと判定）
    const threshold = 0.1;

    // V (Variability) の変化を判定
    final vChange = _determineChange(
      baselineResult.variability,
      interventionResult.variability,
      threshold,
    );

    // I (Instability) の変化を判定
    final iChange = _determineChange(
      baselineResult.instability,
      interventionResult.instability,
      threshold,
    );

    // E (Inertia) の変化を判定
    final eChange = _determineChange(
      baselineResult.inertia,
      interventionResult.inertia,
      threshold,
    );

    // パターンIDを生成
    return _getPatternId(vChange, iChange, eChange);
  }

  /// 値の変化方向を判定
  static String _determineChange(double baseline, double intervention, double threshold) {
    if (baseline == 0) {
      // ベースラインが0の場合は特別処理
      if (intervention > threshold) return '↑';
      if (intervention < -threshold) return '↓';
      return '→';
    }

    final changeRate = (intervention - baseline) / baseline;
    
    if (changeRate > threshold) return '↑';
    if (changeRate < -threshold) return '↓';
    return '→';
  }

  /// 変化パターンからパターンIDを取得
  static String _getPatternId(String vChange, String iChange, String eChange) {
    // グループA: E↓ (心の柔軟性が高まっている)
    if (eChange == '↓') {
      if (vChange == '↓' && iChange == '↓') return 'A-1';
      if (vChange == '→' && iChange == '↓') return 'A-2';
      if (vChange == '↑' && iChange == '↓') return 'A-3';
      if (vChange == '↓' && iChange == '→') return 'A-4';
      if (vChange == '→' && iChange == '→') return 'A-5';
      if (vChange == '↑' && iChange == '→') return 'A-6';
      if (vChange == '↓' && iChange == '↑') return 'A-7';
      if (vChange == '→' && iChange == '↑') return 'A-8';
      if (vChange == '↑' && iChange == '↑') return 'A-9';
    }
    // グループB: E→ (心の柔軟性に変化なし)
    else if (eChange == '→') {
      if (vChange == '↓' && iChange == '↓') return 'B-1';
      if (vChange == '→' && iChange == '↓') return 'B-2';
      if (vChange == '↑' && iChange == '↓') return 'B-3';
      if (vChange == '↓' && iChange == '→') return 'B-4';
      if (vChange == '→' && iChange == '→') return 'B-5';
      if (vChange == '↑' && iChange == '→') return 'B-6';
      if (vChange == '↓' && iChange == '↑') return 'B-7';
      if (vChange == '→' && iChange == '↑') return 'B-8';
      if (vChange == '↑' && iChange == '↑') return 'B-9';
    }
    // グループC: E↑ (心の柔軟性が低下している)
    else {
      if (vChange == '↓' && iChange == '↓') return 'C-1';
      if (vChange == '→' && iChange == '↓') return 'C-2';
      if (vChange == '↑' && iChange == '↓') return 'C-3';
      if (vChange == '↓' && iChange == '→') return 'C-4';
      if (vChange == '→' && iChange == '→') return 'C-5';
      if (vChange == '↑' && iChange == '→') return 'C-6';
      if (vChange == '↓' && iChange == '↑') return 'C-7';
      if (vChange == '→' && iChange == '↑') return 'C-8';
      if (vChange == '↑' && iChange == '↑') return 'C-9';
    }
    
    return 'B-5'; // デフォルト（変化なし）
  }

  /// パターンIDからフィードバックを取得
  static Map<String, dynamic> getFeedbackByPattern(String patternId) {
    return _feedbackMap[patternId] ?? _feedbackMap['B-5']!;
  }

  /// 27パターンのフィードバックマップ
  static final Map<String, Map<String, dynamic>> _feedbackMap = {
    'A-1': {
      'pattern': '感情の波が穏やかになり、安定し、心の柔軟性も高まりました。',
      'interpretation': '感情の振幅と変動が落ち着き、気分を素早く切り替えられる状態です。これは心理的ウェルビーイングが非常に高い「適応的プロファイル」と一致します。',
      'nextStep': '素晴らしい状態です！今のマインドフルネス習慣が心の柔軟性を高めています。この状態を維持しましょう。',
    },
    'A-2': {
      'pattern': '感情の波は先週と同様ですが、より安定し、心の柔軟性も高まっています。',
      'interpretation': '感情の振幅は変わりませんが、瞬間的な変動が減り、気分の切り替えもスムーズになりました。これは感情調節がうまくいっているサインです。',
      'nextStep': '非常に良い傾向です。心の柔軟性を維持するため、日々のマインドフルネスを継続しましょう。',
    },
    'A-3': {
      'pattern': '感情の波は大きくなりましたが、安定しており、心の柔軟性も高まっています。',
      'interpretation': '感情の振幅は大きくなりましたが、変動は安定し、気分を「引きずらない」状態です。感情豊かでありながら、回復力も高い状態です。',
      'nextStep': '感情の豊かさと柔軟性を両立できています。今の心の状態を維持するために、呼吸エクササイズを続けてみましょう。',
    },
    'A-4': {
      'pattern': '感情の波は穏やかになりました。また、心の柔軟性が高まり、気分転換がスムーズです。',
      'interpretation': '感情の振幅は小さくなりましたが、安定性は先週と同様です。重要なのは、感情の慣性が下がり、心の柔軟性が高まった点です。',
      'nextStep': '順調です。心が穏やかで柔軟な状態を保つため、日々の小さな感情の変化に気づく練習を続けましょう。',
    },
    'A-5': {
      'pattern': '感情の波や安定性は先週と同様ですが、心の柔軟性が高まったようです。',
      'interpretation': '安定した感情状態を保ちつつ、感情の持続性が低下しました。これは、ストレスからの回復力が高まっているサインです。',
      'nextStep': '良い変化が起きています。この心の柔軟性をさらに高めるため、5分間のマインドフルネスを試してみましょう。',
    },
    'A-6': {
      'pattern': '感情の波は大きくなりましたが、心の柔軟性（回復力）は高まっています。',
      'interpretation': '感情の振幅は大きくなりましたが、これは必ずしも悪いことではありません。重要なのは、感情の慣性が下がり、気分を「引きずらなくなった」ことです。心の柔軟性が高まっています。',
      'nextStep': '感情の豊かさと柔軟性を両立できています。感情の波を感じたら、それに「乗る」のではなく「眺める」意識（マインドフルネス）を続けましょう。',
    },
    'A-7': {
      'pattern': '感情の波は穏やかになりましたが、少し不安定です。一方、心の柔軟性は高まっています。',
      'interpretation': '感情の振幅は小さくなりましたが、瞬間的な変動は増えています。しかし、気分が長引かないため、柔軟に対応できているようです。',
      'nextStep': '心の柔軟性が高まっているのは良い兆候です。瞬間的な心の揺れに気づくために、マインドフルネスの練習を続けてみましょう。',
    },
    'A-8': {
      'pattern': '感情の波は先週と同様ですが、少し不安定です。一方、心の柔軟性は高まっています。',
      'interpretation': '瞬間的な変動は増えましたが、感情の慣性が低下しているため、気分を素早くリセットできているようです。心の回復力が高まっています。',
      'nextStep': '心の柔軟性は高まっています。日々の小さな心の揺れに振り回されないよう、マインドフルネスで「今ここ」に意識を戻す練習が有効です。',
    },
    'A-9': {
      'pattern': '感情の波が大きく不安定ですが、心の柔軟性（回復力）は高まっています。',
      'interpretation': '感情の振幅や変動は大きくなっていますが、感情の慣性が低下し、気分を「引きずらない」状態です。これは心の柔軟性が高まっている証拠です。',
      'nextStep': '感情の波に気づき、それを手放すことができています。この柔軟性を維持するため、マインドフルネスを継続しましょう。',
    },
    'B-1': {
      'pattern': '感情の波は穏やかになり、安定しましたが、心の柔軟性は変わりません。',
      'interpretation': '感情の振幅と変動が低下し、心が落ち着いた状態です。これは良い兆候です。ただし、感情の持続性は変わらないため、気分転換のパターンは以前と同じかもしれません。',
      'nextStep': '心が穏やかな今、次のステップとして「気分の切り替え」を意識してみましょう。5分間の呼吸エクササイズが役立ちます。',
    },
    'B-2': {
      'pattern': '感情の波は先週と同様ですが、より安定しました。心の柔軟性は変わりません。',
      'interpretation': '感情の振幅は変わりませんが、瞬間的な変動が減りました。心が落ち着き、安定しているサインです。',
      'nextStep': '良い状態を維持できています。この安定した状態を保つため、日々のマインドフルネスを継続しましょう。',
    },
    'B-3': {
      'pattern': '感情の波は大きくなりましたが、安定性は保たれています。心の柔軟性は変わりません。',
      'interpretation': '感情の振幅は大きくなりましたが、瞬間的な変動は抑制されています。感情豊かでありながら、安定もしている状態です。',
      'nextStep': '感情の波が大きくなっています。その感情が良いものであれ悪いものであれ、「ただ眺める」練習としてマインドフルネスを続けてみましょう。',
    },
    'B-4': {
      'pattern': '感情の波が穏やかになりました。安定性や心の柔軟性は先週と同様です。',
      'interpretation': '感情の振幅が小さくなり、心が落ち着いています。これは感情調節がうまくいっているサインです。',
      'nextStep': '心が穏やかな状態を維持できています。この状態を続けられるよう、日々の記録とマインドフルネスを継続しましょう。',
    },
    'B-5': {
      'pattern': '今週の感情パターンは、先週と比べて大きな変化はありませんでした。',
      'interpretation': '感情の変動性、不安定性、持続性ともに、ベースライン期から安定しています。',
      'nextStep': '継続は力なりです。日々の記録とマインドフルネスを続けることで、ご自身の小さな変化に気づきやすくなります。',
    },
    'B-6': {
      'pattern': '感情の波が大きくなりました。安定性や心の柔軟性は先週と同様です。',
      'interpretation': '感情の振幅が大きくなっており、感情的な反応性が高まっているかもしれません。',
      'nextStep': '感情の波が大きくなっています。感情に「飲み込まれる」のではなく、一歩引いて「観察」する練習として、マインドフルネスが役立ちます。',
    },
    'B-7': {
      'pattern': '感情の波は穏やかになりましたが、少し不安定です。心の柔軟性は変わりません。',
      'interpretation': '感情の振幅は小さくなりましたが、瞬間的な変動が増えています。心が落ち着いているように見えても、細かく揺れ動いている状態かもしれません。',
      'nextStep': '心の小さな揺れに気づくことが大切です。マインドフルネスで「今、揺れているな」と客観的に観察する練習を続けましょう。',
    },
    'B-8': {
      'pattern': '感情の波は先週と同様ですが、少し不安定になりました。心の柔軟性は変わりません。',
      'interpretation': '瞬間的な感情の変化が大きくなっています。これは感情が揺れ動きやすく、脆くなっているサインかもしれません。',
      'nextStep': '感情が揺れやすい状態です。その揺れに振り回されないよう、マインドフルネスで心の「軸」を整える練習をしてみましょう。',
    },
    'B-9': {
      'pattern': '感情の波が大きくなり、不安定になりました。心の柔軟性は変わりません。',
      'interpretation': '感情の振幅と変動が大きくなっています。これは、感情的な反応性が高まっているサインかもしれません。気分の切り替えのパターンは変わっていません。',
      'nextStep': '感情の波に飲み込まれそうになったら、「今、自分は強く感じているな」と一歩引いて眺めてみましょう。マインドフルネスがその助けになります。',
    },
    'C-1': {
      'pattern': '感情の波は穏やかになりましたが、気分が「持続」しやすくなっています。',
      'interpretation': '感情の振幅や変動は収まっていますが、感情の慣性が高まっています。これは、気分が「粘着」しやすくなっているサインかもしれません。',
      'nextStep': '心が静かな状態ですが、ネガティブな気分も長引きやすいかもしれません。気分の切り替えを意識し、マインドフルネスで「今ここ」に戻る練習を続けましょう。',
    },
    'C-2': {
      'pattern': '感情の波は先週と同様ですが、安定しています。しかし、気分が「持続」しやすくなっています。',
      'interpretation': '瞬間的な変動は収まりましたが、感情の慣性が高まりました。一度感じた気分が、良くも悪くも長引きやすい状態です。',
      'nextStep': '安定していますが、心の「柔軟性」が少し低下しているようです。気分転換を促すために、軽い運動や5分間のマインドフルネスを取り入れてみましょう。',
    },
    'C-3': {
      'pattern': '感情の波は大きくなりましたが、安定しています。しかし、気分が「持続」しやすくなっています。',
      'interpretation': '感情の振幅は大きくなりましたが、変動は安定しています。ただ、感情の慣性が高まっており、気分が長引きやすいようです。',
      'nextStep': '感情が豊かである一方、気分を「引きずりやすい」かもしれません。マインドフルネスで、過ぎ去った感情を「手放す」練習をしてみましょう。',
    },
    'C-4': {
      'pattern': '感情の波は穏やかになりましたが、気分が「停滞」しやすくなったようです。',
      'interpretation': '感情の振幅は小さくなりましたが、感情の慣性が高まっています。これは心の柔軟性が低下し、ストレスをためやすいことと関連します。',
      'nextStep': '心が穏やかでも、ネガティブな気分が長引くと疲れが溜まります。マインドフルネスで、心の「流れ」を取り戻す練習をしましょう。',
    },
    'C-5': {
      'pattern': '感情の波や安定性は変わりませんが、気分が「停滞」しやすくなったようです。',
      'interpretation': '感情の慣性が高まり、一度感じた気分が長引きやすくなっています。感情の慣性が高い状態は、心の柔軟性が低下し、ストレスをためやすいことと関連します。',
      'nextStep': '心の「流れ」が滞っている感覚かもしれません。マインドフルネスは、この「停滞」に気づき、手放すための良いトレーニングになります。ぜひ5分間試してみてください。',
    },
    'C-6': {
      'pattern': '感情の波が大きくなり、気分も「停滞」しやすくなったようです。',
      'interpretation': '感情の振幅と慣性が共に高まっています。感情に強く反応し、かつ、その気分が長引きやすい状態です。',
      'nextStep': '感情の波が大きく、長引いているようです。少し心が疲れ気味かもしれません。マインドフルネスで、今の感情を優しく「眺める」時間を取りましょう。',
    },
    'C-7': {
      'pattern': '感情の波は穏やかになりましたが、不安定で、気分も「停滞」しやすくなっています。',
      'interpretation': '振幅は小さいですが、瞬間的に変動しやすく、かつ気分が長引く状態です。小さなことに心が揺れ、それを引きずりやすい状態かもしれません。',
      'nextStep': '小さな心の揺れが長引いているようです。心の疲れのサインかもしれません。マインドフルネスで、まずは深く呼吸することから始めましょう。',
    },
    'C-8': {
      'pattern': '感情の波は先週と同様ですが、不安定で、気分も「停滞」しやすくなっています。',
      'interpretation': '感情が不安定で、かつ柔軟性が低い状態です。このパターンは感情調節が難しく、低い心理的ウェルビーイングと関連することが示唆されます。',
      'nextStep': '感情が揺れやすく、気分転換も難しいと感じるかもしれません。無理せず、まずは3分間の呼吸エクササイズで心を落ち着けてみましょう。',
    },
    'C-9': {
      'pattern': '感情の波が大きく、不安定で、気分が「停滞」しやすくなっています。',
      'interpretation': '感情の振幅と変動が大きく、かつ気分が長引きやすい状態です。このパターン（高反応性＋低回復力）は、感情の調節が難しく、低い心理的ウェルビーイングと強く関連することが示唆されています。',
      'nextStep': '少し心が疲れ気味で、感情の波に飲み込まれやすくなっているかもしれません。それはあなたのせいではありません。こういう時こそ、マインドフルネスが役立ちます。無理せず、まずは3分間の呼吸エクササイズから始めてみませんか。',
    },
  };
}

