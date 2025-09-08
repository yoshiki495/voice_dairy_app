import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class CloudRunApiService {
  static const String _baseUrl = 'https://voice-emotion-analysis-354933216254.asia-northeast1.run.app';
  
  /// Firebase ID トークンを取得
  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    try {
      return await user.getIdToken();
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// 認証ヘッダーを生成
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// アップロード用署名付きURL取得
  Future<Map<String, dynamic>?> getUploadUrl({
    required String date,
    String contentType = 'audio/m4a',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/get-upload-url'),
        headers: headers,
        body: jsonEncode({
          'date': date,
          'contentType': contentType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting upload URL: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in getUploadUrl: $e');
      return null;
    }
  }

  /// 感情分析実行
  Future<Map<String, dynamic>?> analyzeEmotion({
    required String storagePath,
    String? recordedAt,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-emotion'),
        headers: headers,
        body: jsonEncode({
          'storagePath': storagePath,
          'recordedAt': recordedAt ?? DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error analyzing emotion: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in analyzeEmotion: $e');
      return null;
    }
  }

  /// 感情データ取得（週次グラフ用）
  Future<Map<String, dynamic>?> getMoodData({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/get-mood-data'),
        headers: headers,
        body: jsonEncode({
          'startDate': startDate,
          'endDate': endDate,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error getting mood data: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in getMoodData: $e');
      return null;
    }
  }

  /// ヘルスチェック
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}
