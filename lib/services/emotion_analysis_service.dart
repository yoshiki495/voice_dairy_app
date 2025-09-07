import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// 感情分析API結果
class EmotionAnalysisResult {
  final double score;           // -1.0 ~ 1.0 (正規化済み)
  final String category;        // positive, neutral, negative
  final double intensity;       // 生の感情強度値
  final DateTime timestamp;

  EmotionAnalysisResult({
    required this.score,
    required this.category,
    required this.intensity,
    required this.timestamp,
  });

  factory EmotionAnalysisResult.fromMap(Map<String, dynamic> map) {
    return EmotionAnalysisResult(
      score: (map['score'] as num).toDouble(),
      category: map['category'] as String,
      intensity: (map['intensity'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// 署名付きURL発行結果
class UploadUrlResult {
  final String uploadUrl;
  final String storagePath;

  UploadUrlResult({
    required this.uploadUrl,
    required this.storagePath,
  });

  factory UploadUrlResult.fromMap(Map<String, dynamic> map) {
    return UploadUrlResult(
      uploadUrl: map['uploadUrl'] as String,
      storagePath: map['storagePath'] as String,
    );
  }
}

/// 感情分析サービス
class EmotionAnalysisService {
  static final EmotionAnalysisService _instance = EmotionAnalysisService._internal();
  factory EmotionAnalysisService() => _instance;
  EmotionAnalysisService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  /// 音声ファイルをアップロードして感情分析を実行
  /// 
  /// [audioFilePath] 音声ファイルのパス
  /// [recordedAt] 録音日時（省略時は現在時刻）
  /// 
  /// Returns: 感情分析結果
  Future<EmotionAnalysisResult> analyzeEmotion({
    required String audioFilePath,
    DateTime? recordedAt,
  }) async {
    try {
      recordedAt ??= DateTime.now();
      
      // 1. 署名付きURL取得
      final uploadResult = await _getUploadUrl(recordedAt);
      
      // 2. 音声ファイルをアップロード
      await _uploadAudioFile(audioFilePath, uploadResult.uploadUrl);
      
      // 3. 感情分析を実行
      final analysisResult = await _performEmotionAnalysis(
        uploadResult.storagePath,
        recordedAt,
      );
      
      return analysisResult;
      
    } catch (e) {
      throw Exception('感情分析に失敗しました: $e');
    }
  }

  /// 署名付きURL発行
  Future<UploadUrlResult> _getUploadUrl(DateTime recordedAt) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(recordedAt);
      
      final callable = _functions.httpsCallable('get_upload_url');
      final result = await callable.call({
        'date': dateString,
        'contentType': 'audio/m4a',
      });

      return UploadUrlResult.fromMap(result.data as Map<String, dynamic>);
      
    } catch (e) {
      throw Exception('署名付きURL取得に失敗しました: $e');
    }
  }

  /// 音声ファイルをFirebase Storageにアップロード
  Future<void> _uploadAudioFile(String filePath, String uploadUrl) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          'Content-Type': 'audio/m4a',
          'Content-Length': bytes.length.toString(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('アップロードに失敗しました: ${response.statusCode}');
      }
      
    } catch (e) {
      throw Exception('音声ファイルのアップロードに失敗しました: $e');
    }
  }

  /// 感情分析を実行
  Future<EmotionAnalysisResult> _performEmotionAnalysis(
    String storagePath,
    DateTime recordedAt,
  ) async {
    try {
      final callable = _functions.httpsCallable('analyze_emotion');
      final result = await callable.call({
        'storagePath': storagePath,
        'recordedAt': recordedAt.toIso8601String(),
      });

      return EmotionAnalysisResult.fromMap(result.data as Map<String, dynamic>);
      
    } catch (e) {
      throw Exception('感情分析の実行に失敗しました: $e');
    }
  }

  /// 指定期間の感情データを取得
  Future<List<EmotionAnalysisResult>> getMoodData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final callable = _functions.httpsCallable('get_mood_data');
      final result = await callable.call({
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
      });

      final data = result.data as Map<String, dynamic>;
      final moods = data['moods'] as List<dynamic>;
      
      return moods.map((mood) {
        final moodMap = mood as Map<String, dynamic>;
        return EmotionAnalysisResult(
          score: (moodMap['score'] as num).toDouble(),
          category: moodMap['category'] as String,
          intensity: (moodMap['intensity'] as num).toDouble(),
          timestamp: moodMap['recordedAt'] != null 
            ? DateTime.parse(moodMap['recordedAt'] as String)
            : DateTime.now(),
        );
      }).toList();
      
    } catch (e) {
      throw Exception('感情データの取得に失敗しました: $e');
    }
  }

  /// 感情カテゴリに基づく色を取得
  static EmotionColor getEmotionColor(String category) {
    switch (category.toLowerCase()) {
      case 'positive':
        return EmotionColor.positive;
      case 'negative':
        return EmotionColor.negative;
      case 'neutral':
      default:
        return EmotionColor.neutral;
    }
  }
}

/// 感情カテゴリ別の色定義
enum EmotionColor {
  positive,
  neutral,
  negative,
}

extension EmotionColorExtension on EmotionColor {
  /// プライマリカラー
  int get primaryColor {
    switch (this) {
      case EmotionColor.positive:
        return 0xFF4CAF50; // Green
      case EmotionColor.neutral:
        return 0xFF9E9E9E; // Grey
      case EmotionColor.negative:
        return 0xFFF44336; // Red
    }
  }

  /// ライトカラー（グラフの背景など）
  int get lightColor {
    switch (this) {
      case EmotionColor.positive:
        return 0xFFE8F5E8; // Light Green
      case EmotionColor.neutral:
        return 0xFFF5F5F5; // Light Grey
      case EmotionColor.negative:
        return 0xFFFFEBEE; // Light Red
    }
  }

  /// 感情カテゴリの日本語名
  String get displayName {
    switch (this) {
      case EmotionColor.positive:
        return 'ポジティブ';
      case EmotionColor.neutral:
        return 'ニュートラル';
      case EmotionColor.negative:
        return 'ネガティブ';
    }
  }
}
