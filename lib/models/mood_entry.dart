enum MoodLabel {
  positive,
  neutral,
  negative;

  static MoodLabel fromScore(double score) {
    if (score >= 0.5) return MoodLabel.positive;
    if (score <= -0.5) return MoodLabel.negative;
    return MoodLabel.neutral;
  }

  static MoodLabel fromCategory(String category) {
    switch (category.toLowerCase()) {
      case 'positive':
        return MoodLabel.positive;
      case 'negative':
        return MoodLabel.negative;
      case 'neutral':
      default:
        return MoodLabel.neutral;
    }
  }

  String get displayName {
    switch (this) {
      case MoodLabel.positive:
        return 'ポジティブ';
      case MoodLabel.neutral:
        return 'ニュートラル';
      case MoodLabel.negative:
        return 'ネガティブ';
    }
  }

  String get emoji {
    switch (this) {
      case MoodLabel.positive:
        return '😊';
      case MoodLabel.neutral:
        return '😐';
      case MoodLabel.negative:
        return '😢';
    }
  }
}

class MoodEntry {
  final String id;
  final String date; // yyyy-MM-dd format
  final double score; // -1.0 to 1.0 (正規化済み)
  final MoodLabel label;
  final double intensity; // 生の感情強度値
  final DateTime recordedAt;
  final String? storagePath; // Firebase Storage path
  final String source;
  final int version;

  const MoodEntry({
    required this.id,
    required this.date,
    required this.score,
    required this.label,
    required this.intensity,
    required this.recordedAt,
    this.storagePath,
    required this.source,
    required this.version,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num).toDouble();
    final intensity = (json['intensity'] as num?)?.toDouble() ?? score;
    
    // categoryフィールドがある場合は優先、なければlabelフィールドを使用
    final category = json['category'] as String?;
    final labelString = json['label'] as String?;
    
    MoodLabel label;
    if (category != null) {
      label = MoodLabel.fromCategory(category);
    } else if (labelString != null) {
      label = MoodLabel.values.firstWhere(
        (e) => e.name == labelString,
        orElse: () => MoodLabel.fromScore(score),
      );
    } else {
      label = MoodLabel.fromScore(score);
    }

    return MoodEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      score: score,
      label: label,
      intensity: intensity,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      storagePath: json['storagePath'] as String? ?? json['gcsUri'] as String?,
      source: json['source'] as String,
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'score': score,
      'category': label.name,
      'intensity': intensity,
      'recordedAt': recordedAt.toIso8601String(),
      'storagePath': storagePath,
      'source': source,
      'version': version,
    };
  }

  MoodEntry copyWith({
    String? id,
    String? date,
    double? score,
    MoodLabel? label,
    double? intensity,
    DateTime? recordedAt,
    String? storagePath,
    String? source,
    int? version,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      score: score ?? this.score,
      label: label ?? this.label,
      intensity: intensity ?? this.intensity,
      recordedAt: recordedAt ?? this.recordedAt,
      storagePath: storagePath ?? this.storagePath,
      source: source ?? this.source,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry &&
           other.id == id &&
           other.date == date &&
           other.score == score &&
           other.label == label &&
           other.intensity == intensity &&
           other.recordedAt == recordedAt &&
           other.storagePath == storagePath &&
           other.source == source &&
           other.version == version;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        score,
        label,
        intensity,
        recordedAt,
        storagePath,
        source,
        version,
      );

  @override
  String toString() {
    return 'MoodEntry(id: $id, date: $date, score: $score, label: $label, intensity: $intensity, recordedAt: $recordedAt, storagePath: $storagePath, source: $source, version: $version)';
  }
}
