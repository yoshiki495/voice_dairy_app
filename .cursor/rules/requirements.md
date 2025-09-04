# iOS（Flutter）アプリ開発要件（詳細版・Flutter対応）

## 1. アプリ概要

- 毎日 **日本時間 20:00** にプッシュ通知（FCM）を送信。
- 通知タップ → 録音画面へ遷移。**最大60秒**の自由発話を録音。
- 音声を **Cloud Run** のAPIへ送信 → 返却された **感情スコア（-1〜1）** を **週次グラフ（月〜日）** に反映。
- **週次グラフ（月〜日）**はアプリ側で録音画面とは別のダッシュボード画面表示する
- **Firebase Authentication（メール＋パスワード）** によるログイン。
- データはユーザー単位で管理。

## 2. 使用技術（Flutter）

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
| ストレージ | **GCS（Google Cloud Storage）** | |

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

1. **推奨フロー（GCS 直アップ）**
   - クライアント → Cloud Run に **署名付きURL発行** を依頼
2. クライアントが GCS に **HTTP PUT** で音声アップ
3. 完了後、クライアント → Cloud Run の `/analyze` へ **メタ情報**（GCSパス等）送信
4. 解析 → スコア返却
- **メリット**: 大きなファイルでもバックエンド負荷軽減・コスト抑制。

## 4. バックエンドAPI仕様（仮）

### 4.1 署名付きURL発行

```http
POST https://<cloud-run>/upload-url
Authorization: Bearer <Firebase ID token>

{
  "path": "audio/<userId>/<YYYY-MM-DD>.m4a",
  "contentType": "audio/m4a"
}
```

**レスポンス**

```json
{
  "uploadUrl": "https://storage.googleapis.com/....?X-Goog-Signature=...",
  "publicUrl": "gs://bucket/audio/<userId>/<YYYY-MM-DD>.m4a"
}
```

### 4.2 解析（スコア取得）

```http
POST https://<cloud-run>/analyze
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "gcsUri": "gs://bucket/audio/<userId>/<YYYY-MM-DD>.m4a",
  "recordedAt": "2025-08-14T20:01:12+09:00"
}
```

**レスポンス**

```json
{
  "score": 0.72,
  "timestamp": "2025-08-14T20:01:15+09:00",
  "label": "positive"  // "negative" | "neutral" もあり
}
```

> 備考: 音声をAPI直送する設計も可能ですが、ネットワーク再送やサイズ制限、Cloud Run のリクエスト時間制限面で 署名URL方式 を推奨。

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
  gcsUri: string      // gs://...
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

- **Server → FCM**: Cloud Scheduler（cron: `0 11 * * *` UTC = JST 20:00） → Cloud Run/Functions → FCM トピック配信 or 個別トークン配信。
- **クライアント**: 初回起動時に `flutter_local_notifications` でフォアグラウンド補助、タイムゾーンは `tz` で **Asia/Tokyo** 固定。

## 8. 認証（無料で便利）

- **Firebase Authentication（メール/パスワード）** を採用。
- 将来拡張：Sign in with Apple（iOS）を `sign_in_with_apple` + **Custom Token** で追加可能（任意）。
- アプリ → Firebase IDトークンを取得 → Cloud Run で検証（`Authorization: Bearer <token>`）。

## 9. エラー処理・リトライ方針

- **dio** でタイムアウト（接続10s/送信60s）・指数バックオフ（最大3回）。
- オフライン時は **送信キュー** に保存し、オンライン復帰時に自動再送。
- 解析失敗時はUIに再試行CTA。
- 署名URL有効期限切れは自動で再発行リクエスト。
