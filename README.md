# Voice Diary App

音声日記アプリケーション - 日々の感情を音声で記録し、可視化するFlutterアプリ

## 概要

Voice Diary Appは、毎日の感情を音声で記録し、その感情スコアを週次グラフで可視化するアプリケーションです。
- 毎日20:00（JST）にプッシュ通知を送信
- 最大60秒の音声録音機能
- Cloud RunのAPIで感情解析（-1〜1のスコア）
- 週次感情グラフの表示（月〜日）
- Firebase認証によるユーザー管理

## 技術スタック

### フロントエンド（Flutter）
- **フレームワーク**: Flutter (Dart 3.x+)
- **UI**: Material 3 / Cupertino（ダークモード対応）
- **状態管理**: Riverpod
- **ナビゲーション**: GoRouter
- **グラフ表示**: fl_chart
- **認証**: Firebase Auth
- **データベース**: Cloud Firestore
- **HTTP通信**: Dio
- **録音**: record パッケージ
- **プッシュ通知**: Firebase Messaging
- **ローカル通知**: flutter_local_notifications

### バックエンド
- **API**: Cloud Run
- **ストレージ**: Google Cloud Storage (GCS)
- **データベース**: Cloud Firestore
- **通知配信**: Firebase Cloud Messaging (FCM)
- **スケジューラー**: Cloud Scheduler

## 主な機能

### 1. 通知機能
- 毎日20:00 JSTに自動プッシュ通知
- 通知タップで録音画面へ遷移
- ローカル再通知機能（20:15 JST）

### 2. 音声録音
- 最大60秒の音声録音
- リアルタイムカウントダウン表示
- 録音・再録・プレビュー機能
- m4a形式（AAC, 44.1kHz, 96kbps）

### 3. 感情解析
- Cloud RunのAPIで音声解析
- 感情スコア算出（-1〜1の範囲）
- Positive/Neutral/Negativeのラベル付け

### 4. データ可視化
- 週次感情グラフ（月〜日）
- 色分け表示：
  - スコア ≥ 0.5: Positive（緑系）
  - -0.5 < スコア < 0.5: Neutral（グレー系）
  - スコア ≤ -0.5: Negative（赤系）

### 5. 認証・ユーザー管理
- Firebase認証（メール・パスワード）
- ユーザー別データ管理
- サインイン・サインアップ・パスワードリセット

## セットアップ

### 必要な環境
- Flutter SDK 3.8.1+
- Dart 3.x+
- iOS 12.0+ / Android API 21+
- Firebase プロジェクト
- Google Cloud Platform アカウント

### インストール手順

1. **リポジトリのクローン**
```bash
git clone <repository-url>
cd voice_dairy_app__frontend
```

2. **依存関係のインストール**
```bash
flutter pub get
```

3. **Firebase設定**
```bash
# Firebase CLIのインストール
npm install -g firebase-tools

# Firebaseプロジェクトの初期化
firebase login
firebase init

# FlutterFire CLIの設定
dart pub global activate flutterfire_cli
flutterfire configure
```

4. **iOS設定**
```bash
cd ios
pod install
cd ..
```

5. **アプリの実行**
```bash
flutter run
```

## プロジェクト構造

```
lib/
├── main.dart                 # アプリエントリーポイント
├── models/                   # データモデル
│   ├── mood_entry.dart      # 感情エントリーモデル
│   └── user.dart            # ユーザーモデル
├── providers/               # Riverpodプロバイダー
│   ├── auth_provider.dart   # 認証状態管理
│   └── mood_provider.dart   # 感情データ管理
├── screens/                 # 画面ウィジェット
│   ├── auth/               # 認証関連画面
│   ├── home/               # ホーム・グラフ画面
│   ├── recording/          # 録音画面
│   └── settings/           # 設定画面
├── services/               # 外部サービス連携
│   └── sample_data_service.dart
├── utils/                  # ユーティリティ
│   └── router.dart         # ルーティング設定
└── widgets/                # 共通ウィジェット
    ├── mood_chart.dart     # 感情グラフ
    └── mood_summary.dart   # 感情サマリー
```

## API仕様

### 署名付きURL発行
```http
POST https://<cloud-run>/upload-url
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "path": "audio/<userId>/<YYYY-MM-DD>.m4a",
  "contentType": "audio/m4a"
}
```

### 感情解析
```http
POST https://<cloud-run>/analyze
Authorization: Bearer <Firebase ID token>
Content-Type: application/json

{
  "gcsUri": "gs://bucket/audio/<userId>/<YYYY-MM-DD>.m4a",
  "recordedAt": "2025-08-14T20:01:12+09:00"
}
```

## データモデル

### Firestore構造
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
  version: number     // スキーマバージョン
```

## 開発・デバッグ

### テスト実行
```bash
flutter test
```

### ビルド
```bash
# iOS
flutter build ios

# Android
flutter build apk
flutter build appbundle
```

### リント・フォーマット
```bash
flutter analyze
dart format .
```

## ライセンス

このプロジェクトは個人利用目的で作成されています。
