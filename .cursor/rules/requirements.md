# iOS（Flutter）アプリ開発要件（詳細版・Flutter対応）

## 1. アプリ概要

- 毎日 **日本時間 20:00** にプッシュ通知（FCM）を送信。
- 通知タップ → 録音画面へ遷移。**最大60秒**の自由発話を録音。
- 音声を **Firebase Functions** のAPIへ送信 → 返却された **感情スコア（-1〜1）** を **週次グラフ（月〜日）** に反映。
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
| API通信 | **cloud_functions** | HTTPS Callable Functions |

### 2.2 Firebase Functions（Python Runtime）

| 項目 | 採用技術/ライブラリ | バージョン | 用途 |
|------|-------------------|-----------|------|
| ランタイム | **Python 3.11** | >= 3.11 | Firebase Functions Gen2 |
| Firebase SDK | **firebase-admin** | >= 6.0.0 | Firebase サービス連携 |
| Functions Framework | **firebase-functions** | >= 0.1.0 | HTTPS Callable |
| 音声特徴量抽出 | **opensmile** | >= 2.5.0 | ComParE_2016 特徴量セット |
| データ処理 | **pandas** | >= 1.5.0 | DataFrame操作 |
| 数値計算 | **numpy** | >= 1.21.0 | 数値演算 |
| 機械学習 | **scikit-learn** | >= 1.1.0 | パイプライン・前処理 |
| モデル保存/読込 | **joblib** | >= 1.2.0 | .pklファイル処理 |
| 勾配ブースティング | **xgboost** | >= 1.6.0 | 分類・回帰モデル |

## 3. 機能要件（詳細）

### 3.1 通知機能

- **方式**: FCM（サーバ起点）＋ アプリ内フォアグラウンド通知は `flutter_local_notifications`。
- **タイミング**: 毎日 20:00 JST（Cloud Scheduler → Cloud Run/Functions → FCM）。
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

1. **Firebase統合フロー**
   - クライアント → Firebase Functions に **署名付きURL発行** を依頼
2. クライアントが Firebase Storage に **HTTP PUT** で音声アップ
3. 完了後、クライアント → Firebase Functions の `analyzeEmotion` へ **メタ情報**（Storageパス等）送信
4. 解析 → スコア返却
- **メリット**: Firebase一括管理、認証自動統合、コスト最適化。

## 4. Firebase Functions API仕様

### 4.1 署名付きURL発行

```dart
// Flutter側（cloud_functions使用）
final callable = FirebaseFunctions.instance.httpsCallable('getUploadUrl');
final result = await callable.call({
  'date': '2025-08-14',
  'contentType': 'audio/m4a'
});
```

**Functions実装例**

```javascript
exports.getUploadUrl = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const bucket = admin.storage().bucket();
    const file = bucket.file(`audio/${context.auth.uid}/${data.date}.m4a`);
    
    const [url] = await file.getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + 15 * 60 * 1000, // 15分
      contentType: 'audio/m4a'
    });
    
    return { uploadUrl: url };
  });
```

### 4.2 感情解析（Python機械学習モデル使用）

```dart
// Flutter側
final callable = FirebaseFunctions.instance.httpsCallable('analyzeEmotion');
final result = await callable.call({
  'storagePath': 'audio/userId/2025-08-14.m4a',
  'recordedAt': '2025-08-14T20:01:12+09:00'
});
```

**Functions実装例（Python Runtime使用）**

```python
import functions_framework
from firebase_admin import initialize_app, firestore, storage
from firebase_functions import https_fn
import opensmile
import pandas as pd
import joblib
import tempfile
import os
from datetime import datetime

# Firebase初期化
initialize_app()

# モデルファイルのロード（起動時に一度だけ）
classifier_pipeline = joblib.load('models/best_emotion_classifier_pipeline.pkl')
regressor_pipeline = joblib.load('models/best_emotion_regressor_pipeline.pkl')
label_encoder = joblib.load('models/label_encoder.pkl')

# openSMILE初期化
smile = opensmile.Smile(
    feature_set=opensmile.FeatureSet.ComParE_2016,
    feature_level=opensmile.FeatureLevel.Functionals
)

@https_fn.on_call(region='asia-northeast1')
def analyze_emotion(req: https_fn.CallableRequest) -> dict:
    # 認証チェック
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message='User must be authenticated'
        )
    
    storage_path = req.data.get('storagePath')
    recorded_at = req.data.get('recordedAt')
    
    try:
        # Firebase Storageから音声ファイルをダウンロード
        bucket = storage.bucket()
        blob = bucket.blob(storage_path)
        
        # 一時ファイルに保存
        with tempfile.NamedTemporaryFile(suffix='.m4a', delete=False) as temp_file:
            blob.download_to_filename(temp_file.name)
            
            # openSMILEで特徴量抽出
            features = smile.process_file(temp_file.name)
            
            # 特徴量の整形（学習時と同じ形式に）
            # 必要に応じて欠損カラムを0で補完
            
            # 感情カテゴリ予測
            emotion_category_num = classifier_pipeline.predict(features)[0]
            emotion_category = label_encoder.inverse_transform([emotion_category_num])[0]
            
            # 感情強度予測
            emotion_intensity = regressor_pipeline.predict(features)[0]
            
            # スコア正規化（-1〜1の範囲に）
            normalized_score = max(-1.0, min(1.0, emotion_intensity))
            
        # 一時ファイル削除
        os.unlink(temp_file.name)
        
        # Firestoreに結果保存
        db = firestore.client()
        date_key = extract_date_from_path(storage_path)
        
        db.collection('users').document(req.auth.uid).collection('moods').document(date_key).set({
            'score': normalized_score,
            'category': emotion_category,
            'intensity': emotion_intensity,
            'recordedAt': firestore.SERVER_TIMESTAMP,
            'storagePath': storage_path,
            'source': 'daily_20_jst',
            'version': 2  # 新しいモデル版
        })
        
        return {
            'score': normalized_score,
            'category': emotion_category,
            'intensity': emotion_intensity,
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f'Emotion analysis failed: {str(e)}'
        )

def extract_date_from_path(path: str) -> str:
    """パスから日付を抽出"""
    return os.path.basename(path).split('.')[0]
```

**必要な依存関係（requirements.txt）**

```
firebase-admin>=6.0.0
firebase-functions>=0.1.0
opensmile>=2.5.0
pandas>=1.5.0
numpy>=1.21.0
scikit-learn>=1.1.0
joblib>=1.2.0
xgboost>=1.6.0
```

### 4.3 スケジュール通知

```javascript
exports.sendDailyNotification = functions
  .region('asia-northeast1')
  .pubsub.schedule('0 11 * * *') // UTC 11:00 = JST 20:00
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    const message = {
      notification: {
        title: '今日の音声日記を記録しましょう',
        body: '1分でOK。今の気分を話してみましょう。'
      },
      topic: 'daily_reminder'
    };
    
    await admin.messaging().send(message);
    console.log('Daily notification sent successfully');
  });
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
  version: number     // スキーマ/モデルのバージョン (v2: ML model)
```

**データ構造の変更点**
- `label` → `category`: より明確な命名
- `intensity`フィールド追加: 機械学習モデルの生の出力値
- `score`: 正規化された値（-1〜1）でグラフ表示用
- `version: 2`: 新しい機械学習モデル使用を示す

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

- **Firebase Functions**: スケジュール関数（cron: `0 11 * * *` UTC = JST 20:00）でFCM トピック配信。
- **クライアント**: 初回起動時に `flutter_local_notifications` でフォアグラウンド補助、タイムゾーンは `tz` で **Asia/Tokyo** 固定。
- **メリット**: Cloud Schedulerが不要、Firebase Consoleで一元管理。

## 8. 認証（無料で便利）

- **Firebase Authentication（メール/パスワード）** を採用。
- 将来拡張：Sign in with Apple（iOS）を `sign_in_with_apple` で追加可能（任意）。
- アプリ → Firebase IDトークンを取得 → Firebase Functions で自動検証（HTTPS Callable）。

