# 🔄 Voice Diary App - アプリ更新手順

## 📋 概要

このドキュメントでは、Voice Diary Appの新しいバージョンを配布する手順について説明します。開発者とテスター双方の作業手順を記載しています。

## 🚀 開発者向け: アプリ更新手順

### 事前準備

#### 1. バージョン管理の確認
```bash
# 現在のバージョンを確認
grep "version:" pubspec.yaml

# Gitの状況を確認
git status
git log --oneline -5
```

#### 2. 変更内容の整理
- 新機能の一覧
- バグ修正の一覧
- 改善点の一覧
- 既知の問題（もしあれば）

### ステップ1: バージョン番号の更新

#### pubspec.yaml の更新
```yaml
# 変更前
version: 1.0.0+1

# 変更後（例）
version: 1.0.1+2
```

**バージョニング規則:**
- **Major.Minor.Patch+Build**
- **Major**: 大きな変更・破壊的変更
- **Minor**: 新機能追加
- **Patch**: バグ修正
- **Build**: ビルド番号（連番）

#### 例
```yaml
# バグ修正リリース
version: 1.0.1+2

# 新機能追加
version: 1.1.0+3

# 大幅な仕様変更
version: 2.0.0+4
```

### ステップ2: テストとビルド

#### 1. ローカルテスト
```bash
# 依存関係の更新
flutter pub get

# 静的解析
flutter analyze

# テストの実行（もしあれば）
flutter test

# ローカルでのビルド確認
flutter build ios --debug
```

#### 2. リリースビルドの作成
```bash
# クリーンビルド
flutter clean
flutter pub get
cd ios && pod install && cd ..

# リリースビルド
flutter build ios --release
```

#### 3. Xcodeでのアーカイブ（必要に応じて）
```bash
# Xcodeワークスペースを開く
open ios/Runner.xcworkspace
```

**Xcodeでの手順:**
1. Product → Archive
2. Archives Organizer で "Distribute App"
3. "Ad Hoc" または "Development" を選択
4. 証明書とプロビジョニングプロファイルを確認
5. Export して IPA ファイルを取得

### ステップ3: Firebase App Distribution にアップロード

#### 基本コマンド
```bash
firebase appdistribution:distribute [IPAファイルのパス] \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --release-notes "[リリースノート]"
```

#### リリースノートの例
```bash
# バグ修正版
firebase appdistribution:distribute ./voice_diary_app.ipa \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --release-notes "v1.0.1 - 録音時のクラッシュ問題を修正、UI表示の改善"

# 新機能版
firebase appdistribution:distribute ./voice_diary_app.ipa \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --release-notes "v1.1.0 - 感情分析結果のエクスポート機能を追加、週別統計表示を改善"
```

#### 特定のテスターグループに配布
```bash
firebase appdistribution:distribute ./voice_diary_app.ipa \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --groups "beta-testers" \
  --release-notes "v1.0.1 - ベータテスター向けリリース"
```

### ステップ4: 配布後の確認

#### 1. Firebase Console での確認
- https://console.firebase.google.com/project/voice-dairy-app-70a9d/appdistribution
- アップロードの成功を確認
- ダウンロード数の監視

#### 2. テスター通知の確認
- 招待済みテスターに自動通知が送信される
- 必要に応じて手動で通知を送信

#### 3. ドキュメントの更新
- README.md
- CHANGELOG.md（もしあれば）
- このドキュメント

### ステップ5: Git でのバージョン管理

```bash
# 変更をコミット
git add .
git commit -m "Release v1.0.1: バグ修正とUI改善"

# タグの作成
git tag -a v1.0.1 -m "Version 1.0.1 release"

# リモートにプッシュ
git push origin main
git push origin v1.0.1
```

## 📱 テスター向け: アプリ更新手順

### 自動通知を受け取った場合

#### 1. 通知の確認
- Firebase App Distribution アプリから通知が届きます
- 「新しいバージョンが利用可能」という内容

#### 2. アップデート手順
1. **Firebase App Distribution アプリを開く**
2. **Voice Diary App を確認**
   - 「更新」ボタンが表示されている
3. **リリースノートを確認**
   - 何が変更されたかを確認
4. **「更新」をタップ**
5. **ダウンロード・インストール完了まで待機**

### 手動で更新を確認する場合

#### 1. Firebase App Distribution アプリを開く
#### 2. リフレッシュ
- アプリ一覧を下に引っ張ってリフレッシュ
#### 3. Voice Diary App の状態を確認
- 「更新」ボタンが表示されている場合は新バージョンあり

### 更新後の確認

#### 1. アプリの動作確認
- 正常に起動することを確認
- 主要機能が動作することを確認

#### 2. データの確認
- 既存のデータが保持されていることを確認
- 設定が引き継がれていることを確認

#### 3. 新機能の確認
- リリースノートに記載された新機能を試す
- 改善点を体験する

## 🚨 緊急更新（Hotfix）手順

### 重大なバグが発見された場合

#### 1. 緊急度の判定
- **Critical**: アプリクラッシュ、データ損失
- **High**: 主要機能の停止
- **Medium**: 軽微な機能問題

#### 2. 迅速な修正とリリース
```bash
# 緊急ブランチの作成（必要に応じて）
git checkout -b hotfix/v1.0.2

# 修正実装後
# バージョン番号をパッチレベルで更新
version: 1.0.2+3

# 迅速なビルドとリリース
flutter build ios --release
firebase appdistribution:distribute ./voice_diary_app.ipa \
  --app 1:354933216254:ios:8db0424cc99dcb368126af \
  --release-notes "緊急修正 v1.0.2 - [重大なバグの説明と修正内容]"
```

#### 3. 緊急通知
- テスターに直接連絡（メール等）
- Firebase Console から手動通知送信

## 📊 更新管理とモニタリング

### バージョン管理表

| バージョン | リリース日 | 主な変更内容 | 重要度 | 状態 |
|-----------|-----------|-------------|-------|------|
| 1.0.0 | 2025-09-11 | 初回リリース | - | 完了 |
| 1.0.1 | 未定 | バグ修正 | Medium | 計画中 |

### モニタリング項目

#### 1. 配布メトリクス
- ダウンロード数
- インストール成功率
- 更新完了率

#### 2. 品質メトリクス
- クラッシュ率
- エラー報告数
- パフォーマンス指標

#### 3. ユーザーフィードバック
- バグ報告
- 機能要望
- 満足度調査

### Firebase Console での確認方法
1. https://console.firebase.google.com/project/voice-dairy-app-70a9d/appdistribution
2. 「リリース」タブでバージョン履歴を確認
3. 「分析」タブでダウンロード数等を確認

## 📝 チェックリスト

### 開発者用リリースチェックリスト

#### リリース前
- [ ] バージョン番号の更新
- [ ] ローカルテストの実行
- [ ] リリースノートの準備
- [ ] リリースビルドの作成
- [ ] IPA ファイルの動作確認

#### リリース時
- [ ] Firebase App Distribution にアップロード
- [ ] アップロード成功の確認
- [ ] テスター通知の送信
- [ ] Git タグの作成
- [ ] ドキュメントの更新

#### リリース後
- [ ] ダウンロード数の確認
- [ ] テスターからのフィードバック収集
- [ ] 問題報告の監視
- [ ] 次バージョンの計画

### テスター用更新チェックリスト

#### 更新前
- [ ] 現在のバージョンの確認
- [ ] 重要なデータのバックアップ（必要に応じて）
- [ ] 更新内容の確認

#### 更新時
- [ ] Firebase App Distribution アプリで更新
- [ ] ダウンロード・インストールの完了確認
- [ ] アプリの正常起動確認

#### 更新後
- [ ] データの保持確認
- [ ] 主要機能の動作確認
- [ ] 新機能の動作確認
- [ ] 問題があれば開発者に報告

## 🔗 関連リンク

- [Firebase App Distribution Console](https://console.firebase.google.com/project/voice-dairy-app-70a9d/appdistribution)
- [配布ガイド](./ios_app_distribution_guide.md)
- [テスター向けガイド](./tester_installation_guide.md)

---

**ドキュメントバージョン**: 1.0  
**最終更新**: 2025年9月11日  
**作成者**: Yoshiki Tanaka
