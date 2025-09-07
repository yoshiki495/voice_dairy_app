# Voice Emotion Analysis API - Cloud Run

Firebase FunctionsからCloud Runに移行した音声感情分析APIです。Flask + Dockerベースで構築されています。

## 📁 ディレクトリ構造

```
cloud_run/
├── main.py                      # Flask API アプリケーション
├── requirements.txt             # Python依存関係
├── Dockerfile                   # Docker設定
├── deploy.sh                    # デプロイスクリプト
├── .dockerignore               # Docker除外ファイル
├── .gcloudignore               # gcloud除外ファイル
├── models/                     # 機械学習モデル
│   ├── best_emotion_classifier_pipeline.pkl
│   ├── best_emotion_regressor_pipeline.pkl
│   ├── label_encoder.pkl
│   └── README.md
└── README.md                   # このファイル
```

## 🚀 デプロイ方法

### 前提条件

1. Google Cloud CLIがインストールされていること
2. 適切なGoogle Cloudプロジェクトにアクセス権があること
3. 機械学習モデルファイルが`models/`ディレクトリに配置されていること

### デプロイ手順

1. **cloud_runディレクトリに移動**
   ```bash
   cd cloud_run
   ```

2. **デプロイスクリプトを実行**
   ```bash
   ./deploy.sh
   ```

   スクリプトは以下を自動実行します：
   - 必要ファイルの存在確認
   - Google Cloud認証確認
   - 必要なAPIの有効化
   - Dockerイメージのビルド
   - Cloud Runへのデプロイ

### 手動デプロイ（オプション）

```bash
# プロジェクト設定
gcloud config set project voice-dairy-app-70a9d

# Dockerイメージビルド
gcloud builds submit --tag gcr.io/voice-dairy-app-70a9d/voice-emotion-analysis

# Cloud Runデプロイ
gcloud run deploy voice-emotion-analysis \
    --image gcr.io/voice-dairy-app-70a9d/voice-emotion-analysis \
    --platform managed \
    --region asia-northeast1 \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 1 \
    --timeout 300
```

## 🔗 API エンドポイント

### 認証不要

- `GET /health` - ヘルスチェック
- `POST /test` - 接続テスト

### 認証必要（Firebase ID Token）

以下のエンドポイントは`Authorization: Bearer <firebase-id-token>`ヘッダーが必要です：

- `POST /get-upload-url` - 音声ファイルアップロード用署名付きURL発行
- `POST /analyze-emotion` - 音声感情分析実行
- `POST /get-mood-data` - ユーザー感情データ取得

## 📊 API仕様

### GET /health

ヘルスチェックエンドポイント

**レスポンス:**
```json
{
    "status": "healthy",
    "timestamp": "2024-01-01T12:00:00.000Z",
    "service": "voice-emotion-analysis"
}
```

### POST /test

接続テスト（認証状態確認可能）

**リクエスト:**
```json
{}
```

**レスポンス:**
```json
{
    "message": "Cloud Run Flask API is working!",
    "timestamp": "2024-01-01T12:00:00.000Z",
    "user_authenticated": true,
    "user_id": "user123"
}
```

### POST /get-upload-url

音声ファイルアップロード用の署名付きURL発行

**リクエスト:**
```json
{
    "date": "2024-01-01",
    "contentType": "audio/m4a"
}
```

**レスポンス:**
```json
{
    "uploadUrl": "https://storage.googleapis.com/...",
    "storagePath": "audio/user123/2024-01-01.m4a"
}
```

### POST /analyze-emotion

音声ファイルから感情分析を実行

**リクエスト:**
```json
{
    "storagePath": "audio/user123/2024-01-01.m4a",
    "recordedAt": "2024-01-01T12:00:00+09:00"
}
```

**レスポンス:**
```json
{
    "score": 0.75,
    "category": "positive",
    "intensity": 0.82,
    "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### POST /get-mood-data

ユーザーの感情データを取得（週次グラフ用）

**リクエスト:**
```json
{
    "startDate": "2024-01-01",
    "endDate": "2024-01-07"
}
```

**レスポンス:**
```json
{
    "moods": [
        {
            "date": "2024-01-01",
            "score": 0.75,
            "category": "positive",
            "intensity": 0.82,
            "recordedAt": "2024-01-01T12:00:00.000Z"
        }
    ],
    "count": 1
}
```

## 🔧 環境変数

- `GOOGLE_CLOUD_PROJECT`: Google CloudプロジェクトID（デフォルト: voice-dairy-app-70a9d）
- `FIRESTORE_DATABASE`: Firestoreデータベース名（デフォルト: default）
- `PORT`: サーバーポート（デフォルト: 8080）

## 📝 機械学習モデル仕様

使用する機械学習モデルについては、`.cursor/rules/emotion_analysis_model_usage.md`を参照してください。

### 必要なモデルファイル

1. `best_emotion_classifier_pipeline.pkl` - 感情カテゴリ分類器
2. `best_emotion_regressor_pipeline.pkl` - 感情強度回帰器
3. `label_encoder.pkl` - ラベルエンコーダー

### 特徴量抽出

- **ライブラリ**: openSMILE
- **特徴量セット**: ComParE_2016
- **特徴量レベル**: Functionals

## 🔍 トラブルシューティング

### デプロイエラー

1. **権限エラー**: Google Cloudの認証を確認
   ```bash
   gcloud auth list
   gcloud auth login  # 必要に応じて
   ```

2. **モデルファイル不足**: modelsディレクトリの内容を確認
   ```bash
   ls -la models/
   ```

3. **メモリ不足**: Dockerfileのメモリ設定を調整

### 実行時エラー

1. **モデル読み込みエラー**: モデルファイルの存在とサイズを確認
2. **Firebase認証エラー**: IDトークンの有効性を確認
3. **Storage接続エラー**: プロジェクトIDとバケット名を確認

## 🚀 Firebase Functionsからの移行

Firebase Functionsからの主な変更点：

1. **認証方式**: Firebase Admin SDKを使用してIDトークンを直接検証
2. **エラーハンドリング**: FlaskのJSONレスポンス形式に変更
3. **リソース制限**: Cloud Runの柔軟なリソース設定を活用
4. **デプロイ**: Dockerベースのデプロイに変更

### Flutterアプリ側の変更

Firebase Functions Callableから通常のHTTP APIへの変更が必要です：

```dart
// 旧: Firebase Functions
final callable = FirebaseFunctions.instance.httpsCallable('analyzeEmotion');
final result = await callable.call(data);

// 新: Cloud Run API
final token = await FirebaseAuth.instance.currentUser?.getIdToken();
final response = await http.post(
  Uri.parse('${cloudRunUrl}/analyze-emotion'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(data),
);
```

## 📋 今後の改善案

- [ ] レスポンス時間の最適化
- [ ] エラーログの詳細化
- [ ] ヘルスチェック機能の拡張
- [ ] モニタリング・メトリクス追加
- [ ] キャッシュ機能の実装
- [ ] A/Bテスト機能の追加
