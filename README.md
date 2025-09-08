# Voice Diary App

音声日記アプリケーション - 日々の感情を音声で記録し、可視化するFlutterアプリ

## 概要

Voice Diary Appは、毎日の感情を音声で記録し、その感情スコアを週次グラフで可視化するアプリケーションです。
- 毎日20:00（JST）にプッシュ通知を送信
- 最大60秒の音声録音機能
- Cloud Run APIで感情解析（-1〜1のスコア）
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
- **API通信**: http (Cloud Run API)
- **録音**: record パッケージ
- **プッシュ通知**: Firebase Messaging
- **ローカル通知**: flutter_local_notifications

### バックエンド
- **API**: Cloud Run (Flask + Docker)
- **ストレージ**: Firebase Storage
- **データベース**: Cloud Firestore
- **通知配信**: Firebase Cloud Messaging (FCM)
- **スケジューラー**: Cloud Scheduler + Cloud Run

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
- Cloud Run APIで音声解析
- 感情スコア算出（-1〜1の範囲）
- Positive/Neutral/Negativeのラベル付け
- Firestoreに自動保存

### 4. データ可視化
- 週次感情グラフ（月〜日）
- 色分け表示：
  - スコア ≥ 0.1: Positive（緑系）
  - -0.1 < スコア < 0.1: Neutral（グレー系）
  - スコア ≤ -0.1: Negative（赤系）

### 5. 認証・ユーザー管理
- Firebase認証（メール・パスワード）
- ユーザー別データ管理
- サインイン・サインアップ・パスワードリセット

## セットアップ

### 必要な環境
- Flutter SDK 3.8.1+
- Dart 3.x+
- iOS 12.0+ / Android API 21+
- Firebase プロジェクト（Storage、Firestore、Auth、Messaging有効化）
- Google Cloud プロジェクト（Cloud Run有効化）

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

## 動作確認手順

### iPhone 16 シミュレーターでの実行

1. **シミュレーターの起動**
```bash
xcrun simctl boot "iPhone 16" && open -a Simulator
```

2. **アプリの実行**
```bash
# シミュレーターが起動したら
flutter run
# デバイス選択画面でiPhone 16を選択
```

### 実機（iPhone）での実行

1. **iPhoneをUSBまたはワイヤレスで接続**
   - USB接続：Lightning/USB-Cケーブルで接続
   - ワイヤレス接続：Xcode > Window > Devices and Simulators でワイヤレス接続を有効化

2. **開発者設定の確認**
   - iPhone: 設定 > 一般 > VPNとデバイス管理 > 開発者アプリ > 信頼
   - Xcode: 自動署名が有効になっていることを確認

3. **アプリの実行**
```bash
flutter run
# デバイス選択画面でiPhoneを選択（例：iPhone (4) (wireless)）
```

### Firebase Authentication の設定

アプリを実行する前に、Firebase Console で認証を有効化してください：

1. [Firebase Console](https://console.firebase.google.com/project/voice-dairy-app-70a9d/authentication/providers) を開く
2. **「Sign-in method」** タブをクリック
3. **「Email/Password」** を選択して有効化
4. **「Save」** をクリック

### テスト用アカウント

Firebase Authentication が有効化された後、以下でテストできます：

**アカウント作成**
- メール: test@example.com
- パスワード: 123456（6文字以上）

**機能テスト**
- サインアップ・サインイン
- 認証状態の自動復元
- エラーハンドリング（無効なメール、短いパスワードなど）

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

## Cloud Run API仕様

### 署名付きURL発行
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

// レスポンス例
{
  "uploadUrl": "https://storage.googleapis.com/..."
}
```

### 感情解析
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

// レスポンス例
{
  "score": 0.72,
  "timestamp": "2025-08-14T20:01:15+09:00",
  "category": "positive"
}
```

### スケジュール通知（サーバーサイド）
```bash
# Cloud Scheduler + Cloud Run
gcloud scheduler jobs create http daily-notification \
  --schedule="0 11 * * *" \
  --uri="${CLOUD_RUN_URL}/send-notification" \
  --time-zone="Asia/Tokyo"
```

## データモデル

### Firestore構造
```
users/{userId}
  email: string
  createdAt: timestamp

users/{userId}/moods/{yyyy-MM-dd}
  score: number       // -1.0 ~ 1.0
  category: string    // "positive" | "neutral" | "negative"
  intensity: number   // 生の感情強度値
  recordedAt: timestamp
  storagePath: string // Firebase Storage path
  source: string      // "daily_20_jst"
  version: number     // スキーマバージョン (v2: Cloud Run API)
```

## デプロイ

### 全体デプロイ手順

**前提条件**:
- Firebase CLI がインストール済み
- Google Cloud CLI がインストール済み  
- 適切な権限でログイン済み

#### 1. 一括デプロイスクリプト実行
```bash
# 全コンポーネントを一括デプロイ
./deploy_all.sh
```

#### 2. 個別デプロイ手順

**Firebase Firestore ルール**:
```bash
firebase deploy --only firestore:rules
```

**Firebase Storage ルール**:
```bash
firebase deploy --only storage
```

**Cloud Run API**:
```bash
cd cloud_run
./deploy.sh
cd ..
```

#### 3. デプロイ後の動作確認

**API ヘルスチェック**:
```bash
curl https://voice-emotion-analysis-354933216254.asia-northeast1.run.app/health
```

**Flutter アプリのビルド**:
```bash
flutter analyze
flutter test
flutter build ios --release
```

### 本番環境URL

- **Cloud Run API**: `https://voice-emotion-analysis-354933216254.asia-northeast1.run.app`
- **Firebase Console**: `https://console.firebase.google.com/project/voice-dairy-app-70a9d`

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
