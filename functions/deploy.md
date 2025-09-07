# Firebase Functions デプロイガイド

## 前提条件

1. **Firebase CLI のインストール**
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase プロジェクトの初期化**
   ```bash
   firebase login
   firebase use --add  # プロジェクトを選択
   ```

3. **Python 3.11 のインストール確認**
   ```bash
   python3 --version  # 3.11以上であることを確認
   ```

## モデルファイルの配置

デプロイ前に、以下の3つのモデルファイルを `functions/models/` ディレクトリに配置してください：

- `best_emotion_classifier_pipeline.pkl`
- `best_emotion_regressor_pipeline.pkl`
- `label_encoder.pkl`

```bash
# ファイルの存在確認
ls -la functions/models/
```

## デプロイ手順

1. **プロジェクトルートディレクトリに移動**
   ```bash
   cd /path/to/voice_dairy_app
   ```

2. **Firebase Functions の初期化（初回のみ）**
   ```bash
   firebase init functions
   ```
   - 言語として Python を選択
   - 既存の functions ディレクトリを使用

3. **デプロイの実行**
   ```bash
   firebase deploy --only functions
   ```

## 個別関数のデプロイ

特定の関数のみデプロイしたい場合：

```bash
# 感情分析関数のみ
firebase deploy --only functions:analyze_emotion

# アップロードURL発行関数のみ
firebase deploy --only functions:get_upload_url

# 感情データ取得関数のみ
firebase deploy --only functions:get_mood_data
```

## 環境変数の設定（必要に応じて）

```bash
# 例：外部APIキーなどの設定
firebase functions:config:set someservice.key="THE API KEY"
```

## ログの確認

```bash
# リアルタイムログ
firebase functions:log

# 特定関数のログ
firebase functions:log --only analyze_emotion
```

## トラブルシューティング

### よくある問題

1. **モデルファイルが見つからない**
   - `functions/models/` ディレクトリに必要な .pkl ファイルがあることを確認

2. **Python依存関係のエラー**
   - `functions/requirements.txt` の内容を確認
   - 必要に応じてバージョンを調整

3. **メモリ不足エラー**
   - Firebase Console で関数のメモリ設定を増加（推奨：2GB以上）

4. **タイムアウトエラー**
   - Firebase Console で関数のタイムアウト設定を増加（推奨：540秒）

### デバッグ方法

1. **ローカルエミュレータでのテスト**
   ```bash
   firebase emulators:start --only functions
   ```

2. **ログレベルの調整**
   - `main.py` 内の `print()` 文でデバッグ情報を出力

## パフォーマンス最適化

1. **コールドスタート対策**
   - グローバル変数でモデルをキャッシュ（実装済み）
   - 最小インスタンス数の設定を検討

2. **メモリ使用量の最適化**
   - 不要な依存関係の削除
   - モデルファイルサイズの最適化

## セキュリティ

1. **認証の確認**
   - すべての関数で `req.auth` チェックを実装済み

2. **CORS設定**
   - 必要に応じて Firebase Console で設定

3. **アクセス制限**
   - Firebase Rules でストレージアクセスを制限
