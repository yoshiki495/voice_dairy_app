# 【旧版】機械学習モデルファイル配置場所

> ⚠️ **重要**: このディレクトリは**バックアップ用**です。  
> Cloud Run APIに移行済みのため、現在使用中のモデルファイルは `cloud_run/models/` にあります。

## 移行完了

機械学習モデルは以下に移行されました：

**現在の場所**: `cloud_run/models/`
- `best_emotion_classifier_pipeline.pkl`
- `best_emotion_regressor_pipeline.pkl`  
- `label_encoder.pkl`

**使用先**: Cloud Run API (`https://voice-emotion-analysis-g5uj2gd3ja-an.a.run.app`)

## Cloud Runでの使用方法

詳細は以下を参照してください：
- **Cloud Run API仕様**: `cloud_run/README.md`
- **モデル使用ガイド**: `.cursor/rules/emotion_analysis_model_usage.md`
- **デプロイ手順**: `cloud_run/deploy.sh`

---

## 以下は旧Firebase Functions用の情報（参考用）

<details>
<summary>旧Firebase Functions用モデル配置情報（参考用）</summary>

### 必要なファイル

1. **`best_emotion_classifier_pipeline.pkl`**
   - 音声特徴量から感情カテゴリ（positive, negative, neutral）を予測する分類器
   - scikit-learn Pipeline オブジェクト

2. **`best_emotion_regressor_pipeline.pkl`**
   - 音声特徴量から感情強度（数値）を予測する回帰器
   - scikit-learn Pipeline オブジェクト

3. **`label_encoder.pkl`**
   - 感情カテゴリの文字列ラベルと数値ラベル間のマッピング
   - sklearn.preprocessing.LabelEncoder オブジェクト

### ファイル配置方法

1. 提供されたモデルファイル（.pkl）をこのディレクトリにコピー
2. ファイル名が上記と完全に一致することを確認
3. Firebase Functionsデプロイ時にこれらのファイルも一緒にアップロードされます

### 注意事項

- これらのファイルは学習済みモデルなので、変更しないでください
- ファイルサイズが大きい場合、Firebase Functionsのデプロイ時間が長くなる可能性があります
- モデルファイルが存在しない場合、Functions実行時にエラーが発生します

### ファイル確認

デプロイ前に以下のコマンドでファイルの存在を確認できます：

```bash
ls -la functions/models/
```

すべてのファイルが存在することを確認してからデプロイしてください。

</details>
