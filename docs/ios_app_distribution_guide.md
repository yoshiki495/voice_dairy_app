# Voice Diary App - iOS配布ガイド

## 📱 概要

このドキュメントでは、Voice Diary AppのiOS版を知り合いに配布する方法について説明します。Firebase App Distributionを使用して、App Storeを経由せずに安全かつ簡単にアプリを配布できます。

## 🏗️ アーキテクチャ

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │───▶│  Firebase        │───▶│   テスター      │
│   (開発者PC)    │    │  App Distribution│    │   (iOSデバイス) │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 💰 コスト

- **Firebase App Distribution**: 完全無料
- **Apple Developer Program**: 不要（無料のApple IDで十分）
- **総コスト**: **無料**

## 🛠️ 必要な環境

### 開発者側
- macOS with Xcode
- Flutter SDK
- Firebase CLI
- Apple ID（無料アカウント）

### テスター側
- iOSデバイス（iPhone/iPad）
- Firebase App Distribution アプリ

## 📋 現在の設定情報

### Firebaseプロジェクト
- **プロジェクト名**: voice-dairy-app-70a9d
- **リージョン**: asia-northeast1

### iOSアプリ設定
- **アプリ名**: Voice Diary App iOS New
- **Bundle ID**: com.yoshiki.voiceDiaryApp
- **App ID**: 1:354933216254:ios:8db0424cc99dcb368126af

### ファイル構成
```
voice_dairy_app/
├── ios/Runner/GoogleService-Info.plist  # Firebase設定ファイル
├── firebase.json                        # Firebase設定
├── .firebaserc                         # Firebaseプロジェクト設定
└── docs/                               # ドキュメント
```

## 🚀 配布手順

### 1. アプリのビルド

```bash
# 依存関係の更新
flutter pub get
cd ios && pod install && cd ..

# クリーンビルド
flutter clean

# リリース用IPAファイルの作成
flutter build ipa --release
```

**注意**: ビルドエラーが発生した場合、Xcodeで手動アーカイブを作成してください。

### 2. Xcodeでのアーカイブ（ビルドエラー時）

```bash
# Xcodeワークスペースを開く
open ios/Runner.xcworkspace
```

**Xcodeでの手順:**
1. Product → Archive
2. Archives Organizer が開く
3. "Distribute App" をクリック
4. "Ad Hoc" または "Development" を選択
5. 適切な証明書とプロビジョニングプロファイルを選択
6. Export して IPA ファイルを取得

### 3. Firebase App Distributionにアップロード

```bash
# アップロードコマンド
firebase appdistribution:distribute [IPAファイルのパス] \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --release-notes "バージョン [X.X.X] - [変更内容の説明]"

# 例
firebase appdistribution:distribute ./voice_diary_app.ipa \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --release-notes "バージョン 1.0.1 - バグ修正とUI改善"
```

### 4. テスターの招待

**Firebase Consoleでの手順:**
1. https://console.firebase.google.com/project/voice-dairy-app-70a9d/appdistribution にアクセス
2. 「テスター」タブをクリック
3. 「テスターを招待」をクリック
4. テスターのメールアドレスを追加
5. 「招待を送信」をクリック

## 👥 テスター向け手順

### 初回セットアップ

1. **招待メールを確認**
   - 開発者から送られた招待メールを開く
   - リンクをタップ

2. **Firebase App Distribution アプリをインストール**
   - App Store から「Firebase App Distribution」をダウンロード
   - https://apps.apple.com/app/firebase-app-distribution/id1477792118

3. **アプリをダウンロード・インストール**
   - Firebase App Distribution アプリを開く
   - Voice Diary App を見つけてインストール

### トラブルシューティング

#### 「信頼されていない開発者」エラー
1. 設定 → 一般 → VPNとデバイス管理
2. 開発者プロファイルを見つける
3. 「信頼」をタップ

#### アプリが見つからない
- 招待メールのリンクを再度確認
- Firebase App Distribution アプリを最新版に更新

## 🔄 アプリ更新手順

### 開発者側

1. **バージョン番号の更新**
   ```yaml
   # pubspec.yaml
   version: 1.0.1+2  # 1.0.0+1 から更新
   ```

2. **新しいビルドの作成**
   ```bash
   flutter build ipa --release
   ```

3. **Firebase App Distributionにアップロード**
   ```bash
   firebase appdistribution:distribute [新しいIPAファイル] \
     --app 1:354933216254:ios:8db0424cc99dcb368126af \
     --release-notes "バージョン 1.0.1 - [変更内容]"
   ```

### テスター側

1. Firebase App Distribution アプリを開く
2. Voice Diary App の「更新」をタップ
3. 新しいバージョンをダウンロード・インストール

## 📊 制限事項

### Firebase App Distribution（無料版）
- **アプリ有効期限**: 90日（再配布で延長可能）
- **ファイルサイズ制限**: 最大150MB
- **テスター数**: 無制限
- **配布回数**: 無制限

### Apple Developer Program（無料アカウント）
- **開発用証明書**: 1年間有効
- **デバイス登録**: 最大100台（年間）
- **アプリ有効期限**: 署名によって異なる

## 🔒 セキュリティ

### アクセス制御
- テスターは招待されたメールアドレスのみアクセス可能
- Firebase App Distribution経由でのみダウンロード可能
- 配布リンクは期限付き

### データ保護
- アプリ内データはFirestoreに暗号化して保存
- 音声ファイルはFirebase Storageで保護
- ユーザー認証はFirebase Authで管理

## 📞 サポート

### よくある質問

**Q: アプリをインストールできません**
A: 以下を確認してください：
- 招待メールのリンクが正しい
- Firebase App Distributionアプリがインストールされている
- デバイス設定で開発者プロファイルを信頼している

**Q: アプリが起動しません**
A: デバイスを再起動してから再度試してください

**Q: アプリが見つかりません**
A: Firebase App Distributionアプリ内でリフレッシュしてください

### 緊急時の連絡先
開発者: [連絡先情報]

## 📈 監視とメトリクス

### Firebase Console でのモニタリング
- ダウンロード数の確認
- クラッシュレポートの監視
- ユーザーフィードバックの確認

### アクセス方法
https://console.firebase.google.com/project/voice-dairy-app-70a9d/appdistribution

## 🔧 メンテナンス

### 定期的な作業
- 90日ごとの再配布（有効期限延長）
- 開発者証明書の更新（年1回）
- Firebase設定の確認

### アップデート頻度
- バグ修正: 即座
- 新機能: 月1回程度
- セキュリティ更新: 即座

---

## 📚 参考リンク

- [Firebase App Distribution公式ドキュメント](https://firebase.google.com/docs/app-distribution)
- [Flutter iOS配布ガイド](https://docs.flutter.dev/deployment/ios)
- [Firebase Console](https://console.firebase.google.com/)

---

**最終更新**: 2025年9月11日
**バージョン**: 1.0
**作成者**: Yoshiki Tanaka
