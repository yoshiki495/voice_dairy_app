import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:voice_diary_app/services/cloud_run_api_service.dart';

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
  final String? uploadUrl;  // nullableに変更
  final String storagePath;

  UploadUrlResult({
    this.uploadUrl,  // requiredを削除
    required this.storagePath,
  });

  factory UploadUrlResult.fromMap(Map<String, dynamic> map) {
    return UploadUrlResult(
      uploadUrl: map['uploadUrl'] as String?,  // nullable castに変更
      storagePath: map['storagePath'] as String,
    );
  }
}

/// 感情分析サービス
class EmotionAnalysisService {
  static final EmotionAnalysisService _instance = EmotionAnalysisService._internal();
  factory EmotionAnalysisService() => _instance;
  EmotionAnalysisService._internal();

  final CloudRunApiService _apiService = CloudRunApiService();

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
      
      // 1. ストレージパス取得
      final uploadResult = await _getUploadUrl(recordedAt);
      
      // 2. Firebase Storageに直接アップロード
      await _uploadAudioFileToFirebase(audioFilePath, uploadResult.storagePath);
      
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
      
      final result = await _apiService.getUploadUrl(
        date: dateString,
        contentType: 'audio/m4a',
      );

      if (result == null) {
        throw Exception('API呼び出しが失敗しました');
      }

      return UploadUrlResult.fromMap(result);
      
    } catch (e) {
      throw Exception('署名付きURL取得に失敗しました: $e');
    }
  }

  /// Firebase Storageに直接アップロード
  Future<void> _uploadAudioFileToFirebase(String filePath, String storagePath) async {
    try {
      final file = File(filePath);
      
      // Firebase Storageのreferenceを取得
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      // ファイルをアップロード
      await storageRef.putFile(file);
      
    } catch (e) {
      throw Exception('Firebase Storageへのアップロードに失敗しました: $e');
    }
  }

  /// 感情分析を実行
  Future<EmotionAnalysisResult> _performEmotionAnalysis(
    String storagePath,
    DateTime recordedAt,
  ) async {
    try {
      final result = await _apiService.analyzeEmotion(
        storagePath: storagePath,
        recordedAt: recordedAt.toIso8601String(),
      );

      if (result == null) {
        throw Exception('API呼び出しが失敗しました');
      }

      return EmotionAnalysisResult.fromMap(result);
      
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
      final result = await _apiService.getMoodData(
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );

      if (result == null) {
        throw Exception('API呼び出しが失敗しました');
      }

      final moods = result['moods'] as List<dynamic>;
      
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
