enum MoodLabel {
  positive,
  neutral,
  negative;

  static MoodLabel fromScore(double score) {
    if (score >= 0.5) return MoodLabel.positive;
    if (score <= -0.5) return MoodLabel.negative;
    return MoodLabel.neutral;
  }

  String get displayName {
    switch (this) {
      case MoodLabel.positive:
        return 'Positive';
      case MoodLabel.neutral:
        return 'Neutral';
      case MoodLabel.negative:
        return 'Negative';
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
  final double score; // -1.0 to 1.0
  final MoodLabel label;
  final DateTime recordedAt;
  final String? gcsUri;
  final String source;
  final int version;

  const MoodEntry({
    required this.id,
    required this.date,
    required this.score,
    required this.label,
    required this.recordedAt,
    this.gcsUri,
    required this.source,
    required this.version,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num).toDouble();
    return MoodEntry(
      id: json['id'] as String,
      date: json['date'] as String,
      score: score,
      label: MoodLabel.values.firstWhere(
        (e) => e.name == json['label'],
        orElse: () => MoodLabel.fromScore(score),
      ),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      gcsUri: json['gcsUri'] as String?,
      source: json['source'] as String,
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'score': score,
      'label': label.name,
      'recordedAt': recordedAt.toIso8601String(),
      'gcsUri': gcsUri,
      'source': source,
      'version': version,
    };
  }

  MoodEntry copyWith({
    String? id,
    String? date,
    double? score,
    MoodLabel? label,
    DateTime? recordedAt,
    String? gcsUri,
    String? source,
    int? version,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      score: score ?? this.score,
      label: label ?? this.label,
      recordedAt: recordedAt ?? this.recordedAt,
      gcsUri: gcsUri ?? this.gcsUri,
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
           other.recordedAt == recordedAt &&
           other.gcsUri == gcsUri &&
           other.source == source &&
           other.version == version;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        score,
        label,
        recordedAt,
        gcsUri,
        source,
        version,
      );

  @override
  String toString() {
    return 'MoodEntry(id: $id, date: $date, score: $score, label: $label, recordedAt: $recordedAt, gcsUri: $gcsUri, source: $source, version: $version)';
  }
}
