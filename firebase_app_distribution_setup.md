# Firebase App Distribution セットアップガイド

## 概要
Firebase App Distributionを使用してiOSアプリを知り合いに配布する手順です。
**費用：無料**（Firebaseの無料枠内）

## 前提条件
- ✅ Flutter開発環境（設定済み）
- ✅ Xcode（設定済み）
- ✅ Firebaseプロジェクト（設定済み）
- Apple ID（無料のアカウントでOK）

## セットアップ手順

### 1. Firebase CLIのインストール・設定

```bash
# Firebase CLIをインストール
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# プロジェクトディレクトリで初期化
firebase use voice-dairy-app-70a9d
```

### 2. App Distributionの有効化

```bash
# App Distributionを有効化
firebase appdistribution:init
```

### 3. テスターグループの作成

Firebase Consoleから：
1. https://console.firebase.google.com にアクセス
2. プロジェクト「voice-dairy-app-70a9d」を選択
3. 左メニューから「App Distribution」を選択
4. 「テスター」タブで新しいグループ「testers」を作成
5. 知り合いのメールアドレスを追加

### 4. iOSアプリの配布

#### 手順A: 自動スクリプトを使用
```bash
./deploy_ios.sh
```

#### 手順B: 手動実行
```bash
# 1. ビルド作成
flutter clean
flutter build ios --release

# 2. Xcodeでアーカイブ
open ios/Runner.xcworkspace
# Product → Archive → Export → Ad Hoc

# 3. Firebase App Distributionにアップロード
firebase appdistribution:distribute path/to/your.ipa \
  --app 1:354933216254:ios:a6c868ed677a7efa8126af \
  --groups "testers" \
  --release-notes "初回リリース $(date '+%Y-%m-%d')"
```

## 知り合いへの配布方法

### テスターの招待
1. Firebase Consoleの「App Distribution」で「テスター」を選択
2. 招待したい人のメールアドレスを追加
3. 「招待を送信」をクリック

### テスター側の手順
1. 招待メールのリンクをクリック
2. Firebase App Distribution iOSアプリをインストール
   - App Store: https://apps.apple.com/app/firebase-app-distribution/id1477792118
3. アプリをダウンロード・インストール

## トラブルシューティング

### よくある問題

#### 1. 「Untrusted Enterprise Developer」エラー
**解決方法：**
- 設定 → 一般 → VPNとデバイス管理
- 開発者プロファイルを「信頼」に設定

#### 2. 「App not installed」エラー
**解決方法：**
- デバイスのiOSバージョンを確認
- プロビジョニングプロファイルの期限確認

#### 3. ビルドエラー
**解決方法：**
```bash
# キャッシュをクリア
flutter clean
cd ios && pod clean && pod install && cd ..
flutter pub get
```

## コスト比較

| 方法 | コスト | 配布人数 | 難易度 |
|------|--------|----------|--------|
| Firebase App Distribution | 無料 | 無制限 | 中 |
| TestFlight | $99/年 | 10,000人 | 易 |
| Enterprise Developer | $299/年 | 無制限 | 難 |

## 制限事項

### Firebase App Distribution（無料）
- アプリの有効期限：90日（再配布で延長可能）
- ファイルサイズ：最大150MB
- 月間配布数：無制限（無料枠内）

### Apple Developer Program（無料アカウント）
- アプリの有効期限：7日
- デバイス登録：最大3台まで
- 開発用証明書の期限：1年

## 次のステップ

1. まず無料のFirebase App Distributionで試す
2. 長期運用が必要な場合はApple Developer Program（$99/年）を検討
3. 多くのユーザーに配布する場合はApp Store公開を検討

## サポート

- Firebase App Distribution: https://firebase.google.com/docs/app-distribution
- Flutter iOS配布: https://docs.flutter.dev/deployment/ios

