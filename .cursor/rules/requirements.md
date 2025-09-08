# iOS（Flutter）アプリ開発要件（詳細版・Flutter対応）

## 1. アプリ概要

- 毎日 **日本時間 20:00** にプッシュ通知（FCM）を送信。
- 通知タップ → 録音画面へ遷移。**最大60秒**の自由発話を録音。
- 音声を **Cloud Run API** へ送信 → 返却された **感情スコア（-1〜1）** を **週次グラフ（月〜日）** に反映。
- **週次グラフ（月〜日）**はアプリ側で録音画面とは別のダッシュボード画面表示する
- **Firebase Authentication（メール＋パスワード）** によるログイン。
- データはユーザー単位で管理。

## 2. 使用技術（Flutter + Firebase一括管理）

### 2.1 Flutter側

| 項目 | 採用技術/パッケージ（候補） | 補足 |
|------|---------------------------|------|
| フレームワーク | Flutter（Stable） | Dart >= 3.x 推奨 |
| UI | Material 3 / Cupertino | ダークモード対応 |
| 状態管理 | **Riverpod** | |
| 録音 | **record** | |
| グラフ | **fl_chart** | |
| プッシュ通知 | **firebase_messaging** | |
| ローカル通知 | **flutter_local_notifications** | |
| 認証 | **firebase_auth** | |
| データベース | **cloud_firestore** | |
| ストレージ | **Firebase Storage** | GCSからFirebase Storageに変更 |
| API通信 | **http** | Cloud Run HTTP API |

### 2.2 Cloud Run API（Python Flask）

| 項目 | 採用技術/ライブラリ | バージョン | 用途 |
|------|-------------------|-----------|------|
| フレームワーク | **Flask** | >= 2.3.0 | Web APIフレームワーク |
| サーバー | **Gunicorn** | >= 21.2.0 | WSGI HTTPサーバー |
| Firebase SDK | **firebase-admin** | >= 6.0.0 | Firebase サービス連携 |
| Google Cloud | **google-cloud-firestore** | >= 2.11.0 | Firestore操作 |
| Google Cloud | **google-cloud-storage** | >= 2.10.0 | Storage操作 |
| 音声特徴量抽出 | **opensmile** | >= 2.5.0 | ComParE_2016 特徴量セット |
| データ処理 | **pandas** | >= 1.5.0 | DataFrame操作 |
| 数値計算 | **numpy** | >= 1.21.0 | 数値演算 |
| 機械学習 | **scikit-learn** | >= 1.1.0 | パイプライン・前処理 |
| モデル保存/読込 | **joblib** | >= 1.2.0 | .pklファイル処理 |
| 勾配ブースティング | **xgboost** | >= 1.6.0 | 分類・回帰モデル |

## 3. 機能要件（詳細）

### 3.1 通知機能

- **方式**: FCM（サーバ起点）＋ アプリ内フォアグラウンド通知は `flutter_local_notifications`。
- **タイミング**: 毎日 20:00 JST（Cloud Scheduler → Cloud Run → FCM）。
- **文面例**:
    - タイトル: `今日の音声日記を記録しましょう`
    - 本文: `1分でOK。今の気分を話してみましょう。`
- **タップ時遷移**: `/record` 画面へディープリンク。
- **失念対策**: アプリ初回起動時に **ローカル再通知（例: 20:15 JST）** をスケジューリング可。

### 3.2 録音

- **最大長**: 60秒（カウントダウン表示）。
- **形式**: m4a（AAC, 44.1kHz, 96kbps 目安）。
- **操作**: 録音開始/停止、再録、（任意で）プレビュー再生。
- **権限**: マイク・通知の許諾フロー（起動直後に説明→OSダイアログ）。
- **失敗時**: ネットワーク不通は **送信キュー** に積んで再試行（指数バックオフ）。

### 3.3 アップロード & 解析

1. **Cloud Run統合フロー**
   - クライアント → Cloud Run API に **署名付きURL発行** を依頼
2. クライアントが Firebase Storage に **HTTP PUT** で音声アップ
3. 完了後、クライアント → Cloud Run API の `analyze-emotion` へ **メタ情報**（Storageパス等）送信
4. 解析 → スコア返却
- **メリット**: Cloud Run自動スケーリング、Firebase認証統合、コスト効率化。

## 4. Cloud Run API仕様

### 4.1 署名付きURL発行

```dart
// Flutter側（http使用）
final response = await http.post(
  Uri.parse('${cloudRunUrl}/get-upload-url'),
  headers: {
    'Authorization': 'Bearer $firebaseIdToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'date': '2025-08-14',
    'contentType': 'audio/m4a'
  }),
);
```

**Cloud Run実装例**

```python
@app.route('/get-upload-url', methods=['POST'])
def get_upload_url():
    # Firebase ID Token認証
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Authentication required'}), 401
    
    token = auth_header.split(' ')[1]
    user_info = _verify_token(token)
    if not user_info:
        return jsonify({'error': 'Invalid token'}), 401
    
    data = request.get_json()
    date = data.get('date')
    content_type = data.get('contentType', 'audio/m4a')
    
    # ストレージパスを生成
    user_id = user_info['uid']
    storage_path = f"audio/{user_id}/{date}.m4a"
    
    # 署名付きURL生成
    storage_client = storage.Client(project=PROJECT_ID)
    bucket = storage_client.bucket(f"{PROJECT_ID}.appspot.com")
    blob = bucket.blob(storage_path)
    
    upload_url = blob.generate_signed_url(
        version="v4",
        expiration=datetime.now().timestamp() + 15 * 60,
        method="PUT",
        content_type=content_type
    )
    
    return jsonify({
        'uploadUrl': upload_url,
        'storagePath': storage_path
    })
```

### 4.2 感情解析（Python機械学習モデル使用）

```dart
// Flutter側
final response = await http.post(
  Uri.parse('${cloudRunUrl}/analyze-emotion'),
  headers: {
    'Authorization': 'Bearer $firebaseIdToken',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'storagePath': 'audio/userId/2025-08-14.m4a',
    'recordedAt': '2025-08-14T20:01:12+09:00'
  }),
);
```

**Cloud Run実装例（Flask使用）**

```python
@app.route('/analyze-emotion', methods=['POST'])
def analyze_emotion():
    # 認証チェック
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Authentication required'}), 401
    
    token = auth_header.split(' ')[1]
    user_info = _verify_token(token)
    if not user_info:
        return jsonify({'error': 'Invalid token'}), 401
    
    # モデルを初期化
    _load_models()
    
    data = request.get_json()
    storage_path = data.get('storagePath')
    recorded_at = data.get('recordedAt')
    
    # Google Cloud Storageから音声ファイルをダウンロード
    storage_client = storage.Client(project=PROJECT_ID)
    bucket = storage_client.bucket(f"{PROJECT_ID}.appspot.com")
    blob = bucket.blob(storage_path)
    
    # 一時ファイルに保存
    with tempfile.NamedTemporaryFile(suffix='.m4a', delete=False) as temp_file:
        blob.download_to_filename(temp_file.name)
        
        # openSMILEで特徴量抽出
        features = _smile.process_file(temp_file.name)
        
        # 感情カテゴリ予測
        emotion_category_num = _classifier_pipeline.predict(features)[0]
        emotion_category = _label_encoder.inverse_transform([emotion_category_num])[0]
        
        # 感情強度予測
        emotion_intensity = _regressor_pipeline.predict(features)[0]
        
        # スコア正規化
        normalized_score = _normalize_score(emotion_intensity)
        
        os.unlink(temp_file.name)
    
    # Firestoreに結果保存
    db = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE)
    date_key = _extract_date_from_path(storage_path)
    user_id = user_info['uid']
    
    mood_data = {
        'score': normalized_score,
        'category': emotion_category,
        'intensity': float(emotion_intensity),
        'recordedAt': firestore.SERVER_TIMESTAMP,
        'storagePath': storage_path,
        'source': 'daily_20_jst',
        'version': 2  # Cloud Run API版
    }
    
    db.collection('users').document(user_id).collection('moods').document(date_key).set(mood_data)
    
    return jsonify({
        'score': normalized_score,
        'category': emotion_category,
        'intensity': float(emotion_intensity),
        'timestamp': datetime.now().isoformat()
    })
```

**必要な依存関係（requirements.txt）**

```
Flask>=2.3.0
gunicorn>=21.2.0
google-cloud-firestore>=2.11.0
google-cloud-storage>=2.10.0
firebase-admin>=6.0.0
opensmile>=2.5.0
pandas>=1.5.0
numpy>=1.21.0
scikit-learn>=1.1.0
joblib>=1.2.0
xgboost>=1.6.0
```

### 4.3 スケジュール通知

```bash
# Cloud Scheduler + Cloud Run
gcloud scheduler jobs create http daily-notification \
  --schedule="0 11 * * *" \
  --uri="${CLOUD_RUN_URL}/send-notification" \
  --time-zone="Asia/Tokyo" \
  --headers="Content-Type=application/json" \
  --http-method=POST
```

## 5. データモデル

### 5.1 Firestore（推奨構造）

```
users/{userId}
  email: string
  createdAt: timestamp

users/{userId}/moods/{yyyy-MM-dd}
  score: number       // -1.0 ~ 1.0 (正規化された感情強度)
  category: string    // "positive" | "neutral" | "negative" (機械学習モデルによる分類)
  intensity: number   // 生の感情強度値（モデル出力）
  recordedAt: timestamp
  storagePath: string // Firebase Storage path
  source: string      // "daily_20_jst"
  version: number     // スキーマ/モデルのバージョン (v2: Cloud Run API)
```

**データ構造の変更点**
- `label` → `category`: より明確な命名
- `intensity`フィールド追加: 機械学習モデルの生の出力値
- `score`: 正規化された値（-1〜1）でグラフ表示用
- `version: 2`: Cloud Run APIモデル使用を示す

### 5.2 命名・キー

- ドキュメントIDに日付（JST）を用いることで週次/日次集計が容易。

## 6. 画面要件（Flutter）

### 6.1 認証フロー

- 画面: サインイン/サインアップ、パスワードリセット。
- バリデーション・エラーメッセージ整備。
- ログイン成功 → `/home`。

### 6.2 ホーム（週次グラフ）

- **グラフ**: fl_chart LineChart/BarChart（縦軸: -1〜1, 横軸: 月〜日）。
- **色分け**（UIルール）：
    - score ≥ 0.5: Positive（緑系）
    - -0.5 < score < 0.5: Neutral（グレー系）
    - score ≤ -0.5: Negative（赤系）
- **追加表示情報**:
    - 各データポイントにカテゴリラベル（positive/neutral/negative）を表示
    - タップ時に詳細情報（感情強度の生値、録音日時）をポップアップ表示
- 当日分が未入力ならバナーで「録音しませんか？」を表示。

### 6.3 録音

- タイマー/波形（簡易アニメーションで可）。
- 再録・送信ボタン。送信中は進捗インジケータ。
- 成功時スナックバー「感情: Positive（強度: 0.72）を記録しました」。

### 6.4 設定

- 通知オン/オフ、再通知時刻（任意）。
- ログアウト。

## 7. 通知スケジュール

- **Cloud Scheduler + Cloud Run**: スケジュール関数（cron: `0 11 * * *` UTC = JST 20:00）でFCM トピック配信。
- **クライアント**: 初回起動時に `flutter_local_notifications` でフォアグラウンド補助、タイムゾーンは `tz` で **Asia/Tokyo** 固定。
- **メリット**: Cloud Runの自動スケーリング、柔軟なリソース設定。

## 8. 認証（無料で便利）

- **Firebase Authentication（メール/パスワード）** を採用。
- 将来拡張：Sign in with Apple（iOS）を `sign_in_with_apple` で追加可能（任意）。
- アプリ → Firebase IDトークンを取得 → Cloud Run API で自動検証（HTTP API + Bearer Token）。

## 9. デプロイ手順

### 9.1 全体デプロイ

**一括デプロイスクリプト**:
```bash
./deploy_all.sh
```

**個別デプロイ**:
```bash
# Firebase ルール
firebase deploy --only firestore:rules
firebase deploy --only storage

# Cloud Run API
cd cloud_run && ./deploy.sh && cd ..
```

### 9.2 本番環境URL

- **Cloud Run API**: `https://voice-emotion-analysis-354933216254.asia-northeast1.run.app`
- **Firebase Console**: `https://console.firebase.google.com/project/voice-dairy-app-70a9d`

### 9.3 デプロイ後確認

```bash
# API ヘルスチェック
curl https://voice-emotion-analysis-354933216254.asia-northeast1.run.app/health

# Flutter アプリ確認
flutter analyze
flutter test
```

