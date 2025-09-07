# Flutter → Cloud Run API 統合ガイド

Firebase FunctionsからCloud Run APIへの移行に伴うFlutterアプリの変更手順です。

## 🔄 主な変更点

### Before: Firebase Functions Callable
```dart
final callable = FirebaseFunctions.instance.httpsCallable('analyzeEmotion');
final result = await callable.call(data);
```

### After: Cloud Run HTTP API
```dart
final response = await http.post(
  Uri.parse('${cloudRunUrl}/analyze-emotion'),
  headers: {
    'Authorization': 'Bearer $firebaseIdToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(data),
);
```

## 📱 Flutter アプリ側の実装

### 1. 依存関係の追加

`pubspec.yaml`に以下を追加：

```yaml
dependencies:
  http: ^1.1.0
  # 既存の依存関係はそのまま維持
  firebase_auth: ^4.15.3
  firebase_core: ^2.24.2
```

### 2. Cloud Run API サービスクラスの作成

```dart
// lib/services/cloud_run_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class CloudRunApiService {
  static const String _baseUrl = 'https://voice-emotion-analysis-g5uj2gd3ja-an.a.run.app';
  
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
```

### 3. 既存サービスの更新

既存の`EmotionAnalysisService`を更新：

```dart
// lib/services/emotion_analysis_service.dart
import 'package:voice_diary_app/services/cloud_run_api_service.dart';

class EmotionAnalysisService {
  final CloudRunApiService _apiService = CloudRunApiService();

  /// 音声ファイルのアップロードと感情分析
  Future<Map<String, dynamic>?> uploadAndAnalyzeAudio({
    required String audioFilePath,
    required String date,
  }) async {
    try {
      // 1. 署名付きURL取得
      final uploadResult = await _apiService.getUploadUrl(date: date);
      if (uploadResult == null) {
        throw Exception('Failed to get upload URL');
      }

      final uploadUrl = uploadResult['uploadUrl'] as String;
      final storagePath = uploadResult['storagePath'] as String;

      // 2. 音声ファイルをCloud Storageにアップロード
      final audioBytes = await File(audioFilePath).readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        body: audioBytes,
        headers: {'Content-Type': 'audio/m4a'},
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload audio file');
      }

      // 3. 感情分析実行
      final analysisResult = await _apiService.analyzeEmotion(
        storagePath: storagePath,
        recordedAt: DateTime.now().toIso8601String(),
      );

      return analysisResult;
    } catch (e) {
      print('Error in uploadAndAnalyzeAudio: $e');
      return null;
    }
  }

  /// 週次感情データ取得
  Future<List<Map<String, dynamic>>> getWeeklyMoodData(DateTime startDate) async {
    final endDate = startDate.add(const Duration(days: 6));
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final result = await _apiService.getMoodData(
      startDate: dateFormat.format(startDate),
      endDate: dateFormat.format(endDate),
    );

    if (result != null && result['moods'] != null) {
      return List<Map<String, dynamic>>.from(result['moods']);
    }
    
    return [];
  }
}
```

### 4. Provider/状態管理の更新

Riverpodを使用している場合：

```dart
// lib/providers/emotion_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_diary_app/services/emotion_analysis_service.dart';

final emotionAnalysisServiceProvider = Provider<EmotionAnalysisService>((ref) {
  return EmotionAnalysisService();
});

final weeklyMoodDataProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, startDate) async {
  final service = ref.read(emotionAnalysisServiceProvider);
  return await service.getWeeklyMoodData(startDate);
});
```

### 5. UI層での使用例

録音画面での使用例：

```dart
// lib/screens/recording/recording_screen.dart
class RecordingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // ... UI構成
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_isRecording) {
            await _stopRecording(ref);
          } else {
            await _startRecording();
          }
        },
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }

  Future<void> _stopRecording(WidgetRef ref) async {
    // 録音停止処理
    final audioPath = await _recordingService.stopRecording();
    
    if (audioPath != null) {
      // 感情分析実行
      _showAnalysisDialog(context);
      
      final service = ref.read(emotionAnalysisServiceProvider);
      final result = await service.uploadAndAnalyzeAudio(
        audioFilePath: audioPath,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );

      Navigator.of(context).pop(); // ダイアログを閉じる

      if (result != null) {
        _showResultDialog(context, result);
      } else {
        _showErrorDialog(context);
      }
    }
  }

  void _showResultDialog(BuildContext context, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('感情分析完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('感情: ${result['category']}'),
            Text('スコア: ${result['score'].toStringAsFixed(2)}'),
            Text('強度: ${result['intensity'].toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

ホーム画面での使用例：

```dart
// lib/screens/home/home_screen.dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startDate = _getWeekStartDate();
    final moodDataAsync = ref.watch(weeklyMoodDataProvider(startDate));

    return Scaffold(
      body: moodDataAsync.when(
        data: (moodData) => MoodChart(moodData: moodData),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }

  DateTime _getWeekStartDate() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }
}
```

## 🔧 設定

### 1. Cloud Run URL の管理

アプリの設定に基づいてURLを管理することを推奨：

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String cloudRunBaseUrl = String.fromEnvironment(
    'CLOUD_RUN_URL',
    defaultValue: 'https://voice-emotion-analysis-g5uj2gd3ja-an.a.run.app',
  );
}
```

ビルド時にURLを指定：

```bash
# 本番環境
flutter build apk --dart-define=CLOUD_RUN_URL=https://voice-emotion-analysis-g5uj2gd3ja-an.a.run.app

# 開発環境
flutter build apk --dart-define=CLOUD_RUN_URL=https://dev-voice-emotion-analysis-xxx.run.app
```

### 2. エラーハンドリング

適切なエラーハンドリングを実装：

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

// CloudRunApiService内でのエラーハンドリング例
Future<Map<String, dynamic>?> analyzeEmotion({...}) async {
  try {
    final response = await http.post(...);
    
    if (response.statusCode == 401) {
      throw ApiException('認証が必要です', statusCode: 401);
    } else if (response.statusCode == 404) {
      throw ApiException('音声ファイルが見つかりません', statusCode: 404);
    } else if (response.statusCode != 200) {
      throw ApiException('サーバーエラーが発生しました', statusCode: response.statusCode);
    }
    
    return jsonDecode(response.body);
  } on ApiException {
    rethrow;
  } catch (e) {
    throw ApiException('ネットワークエラーが発生しました: $e');
  }
}
```

## 🧪 テスト

### 1. APIサービスのテスト

```dart
// test/services/cloud_run_api_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:voice_diary_app/services/cloud_run_api_service.dart';

void main() {
  group('CloudRunApiService', () {
    late CloudRunApiService service;

    setUp(() {
      service = CloudRunApiService();
    });

    test('should return health check success', () async {
      final result = await service.healthCheck();
      expect(result, isTrue);
    });

    // その他のテストケース...
  });
}
```

### 2. 統合テスト

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voice_diary_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('recording and emotion analysis flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 録音ボタンをタップ
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // 録音停止
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // 分析結果が表示されることを確認
      expect(find.text('感情分析完了'), findsOneWidget);
    });
  });
}
```

## 📋 チェックリスト

移行作業完了前の確認事項：

- [ ] Cloud Run APIが正常にデプロイされている
- [ ] Firebase認証が正常に動作する
- [ ] 録音→アップロード→分析のフローが動作する
- [ ] 週次グラフデータ取得が動作する
- [ ] エラーハンドリングが適切に実装されている
- [ ] 本番環境とdev環境の設定が分離されている
- [ ] 既存のFirebase Functions依存関係が削除されている

## 🚀 デプロイ

Flutter Webの場合、CORS設定が必要な場合があります：

```dart
// Cloud Run main.py にCORS設定を追加
from flask_cors import CORS

app = Flask(__name__)
CORS(app, origins=['https://your-flutter-web-domain.com'])
```

完了後は、Firebase Functions関連の古いコードを削除してプロジェクトをクリーンアップしてください。
