# 機械学習モデルファイル配置場所

このディレクトリには、音声感情分析に必要な以下の3つのモデルファイルを配置してください：

## 必要なファイル

1. **`best_emotion_classifier_pipeline.pkl`**
   - 音声特徴量から感情カテゴリ（positive, negative, neutral）を予測する分類器
   - scikit-learn Pipeline オブジェクト

2. **`best_emotion_regressor_pipeline.pkl`**
   - 音声特徴量から感情強度（数値）を予測する回帰器
   - scikit-learn Pipeline オブジェクト

3. **`label_encoder.pkl`**
   - 感情カテゴリの文字列ラベルと数値ラベル間のマッピング
   - sklearn.preprocessing.LabelEncoder オブジェクト

## ファイル配置方法

1. 提供されたモデルファイル（.pkl）をこのディレクトリにコピー
2. ファイル名が上記と完全に一致することを確認
3. Cloud Runデプロイ時にこれらのファイルも一緒にDockerイメージに含まれます

## 注意事項

- これらのファイルは学習済みモデルなので、変更しないでください
- ファイルサイズが大きい場合、Dockerイメージのビルド時間が長くなる可能性があります
- モデルファイルが存在しない場合、API実行時にエラーが発生します

## ファイル確認

デプロイ前に以下のコマンドでファイルの存在を確認できます：

```bash
ls -la cloud_run/models/
```

すべてのファイルが存在することを確認してからデプロイしてください。