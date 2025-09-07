# 音声感情分析モデル ファイル利用説明書

このドキュメントは、音声感情分析モデルを利用した API を開発する開発者向けに、必要なファイルとその利用方法を説明します。

## 提供されるファイル

以下の 3 つのファイルが提供されます。これらはモデルの学習プロセスで生成されています。

1. **`best_emotion_classifier_pipeline.pkl`**: 音声の特徴量から感情カテゴリ（positive, negative, neutral）を予測するための機械学習モデル（scikit-learn Pipeline オブジェクト）。特徴量抽出後のデータを受け取り、前処理（欠損値補完、特徴量選択）を経て、分類器で予測を行います。
2. **`best_emotion_regressor_pipeline.pkl`**: 音声の特徴量から感情強度（数値）を予測するための機械学習モデル（scikit-learn Pipeline オブジェクト）。特徴量抽出後のデータを受け取り、前処理（欠損値補完、特徴量選択）を経て、回帰器で予測を行います。
3. **`label_encoder.pkl`**: 感情カテゴリの文字列ラベル（'positive', 'negative', 'neutral'）と数値ラベル間のマッピング情報を持つ LabelEncoder オブジェクト。分類モデルの出力（数値）を元の文字列ラベルに戻すために使用します。

## API 開発に必要な要素

API を構築するには、上記のファイルに加えて以下の要素が必要です。

*   **opensmile ライブラリ**: 音声ファイルから特徴量を抽出するために使用します。学習時と同じ FeatureSet と FeatureLevel（ComParE_2016, Functionals）を使用する必要があります。
*   **Python 環境と必要なライブラリ**: Python 3.6 以上を推奨します。以下のライブラリが必要です。
    *   `opensmile`
    *   `pandas`
    *   `numpy`
    *   `scikit-learn` (モデルのバージョンと互換性のあるもの)
    *   `joblib` (`.pkl` ファイルの読み込みに使用)
    *   `xgboost` (学習で XGBoost が使用されている場合)

## API 実装のワークフロー

API エンドポイントは、以下のステップで処理を行う必要があります。

1.  **入力の受付**: API は音声データ（ファイルパスやバイトデータなど）を受け取ります。
    *   **想定される入力**: 音声ファイルのパス、または音声データのバイト列。サポートされるフォーマットは opensmile が対応しているもの（例: WAV）。
2.  **特徴量抽出**:
    *   opensmile を使用して、入力音声データから学習時と同じ特徴量を抽出します。
    *   使用する opensmile.Smile オブジェクトは、学習時と同じ `feature_set` と `feature_level` で初期化する必要があります。
    *   例: `smile = opensmile.Smile(feature_set=opensmile.FeatureSet.ComParE_2016, feature_level=opensmile.FeatureLevel.Functionals)`
    *   `smile.process_file(audio_filepath)` のように音声ファイルを処理します。音声データのバイト列から処理する場合は opensmile のドキュメントを参照してください。
    *   抽出された特徴量は pandas DataFrame として得られます。
3.  **特徴量データの整形**:
    *   抽出された特徴量 DataFrame のカラムが、学習に使用した特徴量のカラムと一致していることを確認します。
    *   学習データに存在したが抽出データに存在しないカラムがある場合、それらのカラムを追加し、値を 0 で埋めます。これは、`SelectKBest` が期待する入力形式に合わせるためです。
    *   学習時の特徴量カラムのリスト (`X.columns`) は、学習プロセス中に保存しておくか、または `best_emotion_classifier_pipeline.pkl` または `best_emotion_regressor_pipeline.pkl` をロードした後にパイプライン内のセレクタオブジェクトから取得できる場合があります（例: `loaded_clf_pipeline.named_steps['selector'].get_support(indices=True)` でインデックスを取得し、元のカラムリストから名前を取得）。最も確実なのは、学習時に使用した `X.columns` を別途保存しておくことです。
    *   カラムの順序も学習時と一致させるのが安全です。
4.  **モデルのロード**:
    *   API の起動時などに、`joblib.load()` を使用して `best_emotion_classifier_pipeline.pkl`, `best_emotion_regressor_pipeline.pkl`, `label_encoder.pkl` をメモリにロードします。
5.  **予測の実行**:
    *   整形した特徴量データをロードした分類モデルパイプライン (`loaded_clf_pipeline`) に入力し、感情カテゴリの予測（数値ラベル）を取得します。
    *   予測された数値ラベルをロードした LabelEncoder (`loaded_le`) を使用して、元の文字列ラベルに変換します（例: `loaded_le.inverse_transform([predicted_numerical_label])[0]`）。
    *   整形した特徴量データをロードした回帰モデルパイプライン (`loaded_reg_pipeline`) に入力し、感情強度の予測（数値）を取得します。
6.  **結果の返却**:
    *   予測された感情カテゴリ（文字列ラベル）と感情強度（数値）を API のレスポンスとして返却します。
    *   **想定される出力**: 例: `{'emotion_category': 'negative', 'emotion_intensity': 1.56}` のような JSON オブジェクト形式。
