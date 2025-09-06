# iOS（Flutter）アプリ開発要件（詳細版・Flutter対応）

## 1. アプリ概要

- 毎日 **日本時間 20:00** にプッシュ通知（FCM）を送信。
- 通知タップ → 録音画面へ遷移。**最大60秒**の自由発話を録音。
- 音声を **Firebase Functions** のAPIへ送信 → 返却された **感情スコア（-1〜1）** を **週次グラフ（月〜日）** に反映。
- **週次グラフ（月〜日）**はアプリ側で録音画面とは別のダッシュボード画面表示する
- **Firebase Authentication（メール＋パスワード）** によるログイン。
- データはユーザー単位で管理。

## 2. 使用技術（Flutter + Firebase一括管理）

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

### 4.2 感情解析

```dart
// Flutter側
final callable = FirebaseFunctions.instance.httpsCallable('analyzeEmotion');
final result = await callable.call({
  'storagePath': 'audio/userId/2025-08-14.m4a',
  'recordedAt': '2025-08-14T20:01:12+09:00'
});
```

**Functions実装例**

```javascript
exports.analyzeEmotion = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const { storagePath, recordedAt } = data;
    
    // 感情分析ロジック（Speech-to-Text + Natural Language AI など）
    const score = await performEmotionAnalysis(storagePath);
    
    // Firestoreに結果保存
    await admin.firestore()
      .collection('users').doc(context.auth.uid)
      .collection('moods').doc(extractDateFromPath(storagePath))
      .set({
        score,
        label: score >= 0.5 ? 'positive' : score <= -0.5 ? 'negative' : 'neutral',
        recordedAt: admin.firestore.Timestamp.fromDate(new Date(recordedAt)),
        storagePath,
        source: 'daily_20_jst',
        version: 1
      });
    
    return {
      score,
      timestamp: new Date().toISOString(),
      label: score >= 0.5 ? 'positive' : score <= -0.5 ? 'negative' : 'neutral'
    };
  });
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
  score: number       // -1.0 ~ 1.0
  label: string       // "positive" | "neutral" | "negative"
  recordedAt: timestamp
  storagePath: string // Firebase Storage path
  source: string      // "daily_20_jst"
  version: number     // スキーマ/モデルのバージョン
```

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
    - score ≥ 0.5: Positive
    - 0.5 < score < 0.5: Neutral
    - score ≤ -0.5: Negative
- 当日分が未入力ならバナーで「録音しませんか？」を表示。

### 6.3 録音

- タイマー/波形（簡易アニメーションで可）。
- 再録・送信ボタン。送信中は進捗インジケータ。
- 成功時スナックバー「スコア: 0.72（Positive）を記録しました」。

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

