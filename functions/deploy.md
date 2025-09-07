# 【廃止予定】Firebase Functions デプロイガイド

> ⚠️ **重要**: このドキュメントは廃止予定です。  
> Firebase FunctionsからCloud Runに移行しました。  
> 新しいデプロイ手順は `cloud_run/README.md` を参照してください。

## 移行済み項目

このFunctionsは以下のCloud Run APIに移行されました：

- **感情分析API**: `https://voice-emotion-analysis-g5uj2gd3ja-an.a.run.app`
- **デプロイ手順**: `cloud_run/deploy.sh`
- **ドキュメント**: `cloud_run/README.md`

## Cloud Runへの移行手順

1. **Cloud Run APIのデプロイ**
   ```bash
   cd cloud_run
   ./deploy.sh
   ```

2. **Flutter アプリの更新**
   - 詳細は `docs/flutter_cloud_run_integration.md` を参照

3. **Firebase Functions の無効化**
   ```bash
   # 必要に応じてFunctionsを削除
   firebase functions:delete analyze_emotion
   firebase functions:delete get_upload_url
   firebase functions:delete get_mood_data
   ```

## 移行の利点

- **自動スケーリング**: Cloud Runの柔軟なスケーリング
- **コスト削減**: 使用時のみ課金
- **パフォーマンス向上**: 専用リソースでの安定動作
- **メンテナンス性**: Dockerベースの統一環境

---

## 以下は旧Firebase Functions用の情報（参考用）

<details>
<summary>旧Firebase Functionsデプロイ手順（参考用）</summary>

### 前提条件

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

### モデルファイルの配置

デプロイ前に、以下の3つのモデルファイルを `functions/models/` ディレクトリに配置してください：

- `best_emotion_classifier_pipeline.pkl`
- `best_emotion_regressor_pipeline.pkl`
- `label_encoder.pkl`

```bash
# ファイルの存在確認
ls -la functions/models/
```

### デプロイ手順

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

</details>
