# 音声フィードバックによるウェルビーイング向上システム

**発表者**: 田中 善貴  
**所属**: 青山学院大学 宮治研究室  
**日付**: 2025年11月5日

---

## 目次

1. [背景](#1-背景)
2. [目的と手法](#2-目的と手法)
3. [システム概要](#3-システム概要)
4. [予備実験](#4-予備実験)
5. [今後の予定](#5-今後の予定)

---

## 1. 背景

### WHO憲章の健康定義

> "Health is a state of complete physical, mental and social well-being and not merely the absence of disease or infirmity."

**日本語訳**  
健康とは、単に疾病または病弱の存在しないことではなく、身体的、精神的及び社会的に完全なウェルビーイングの状態である

**（出典: WHO憲章）**

### ウェルビーイングの定義と3つの柱

#### ウェルビーイング (Well-being) とは

WHO憲章による健康の定義に含まれる身体的、精神的及び社会的に満たされている状態

#### ウェルビーイングを構成する3つの柱

1. **身体的ウェルビーイング**
2. **精神的ウェルビーイング**
3. **社会的ウェルビーイング**

**（出典: WHO憲章）**

### ウェルビーイング向上の社会的意義

#### 経済効果

- **世界経済成長**: 11.7兆ドル
  - *出典: World Economic Forum (WEF) Thriving Workplaces レポート (2025)*

#### 職場生産性向上

- **業務効率**: 21%向上
- **欠勤**: 30%削減
  - *出典: PMC/Gallup研究データ Gallupの従業員エンゲージメント研究(2019)*

#### 医療費削減

- **世界の労働損失**: 1兆ドル/年
  - *出典: World Health Organization (WHO) WHOメンタルヘルス職場ガイドライン (2022)*

#### 社会問題解決

- **健康平等性でGDP増加**
  - *出典: Deloitte研究 健康平等性の経済効果分析 (2040年予測)*

---

## 2. 目的と手法

### 研究目的と手法

#### 目的

ウェルビーイングを向上させるシステムの開発

#### 手法

音声入力を元に感情ダイナミクスを取得・利用

### ウェルビーイング向上の具体的な方法

#### 方法

精神的ウェルビーイングに含まれる**心理的ウェルビーイング**の向上

#### 心理的ウェルビーイングの定義

> ポジティブな感情、幸福、高い自尊心、あるいは生活満足度といった心理的適応のポジティブな指標の存在、および/または、ネガティブな感情、精神病理学的症状、診断といった心理的不適応の指標の不在のいずれか、あるいは両方を含む広範な構成概念

**（出典: The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis (2015)）**

### 精神的ウェルビーイング向上の類似研究

#### 類似研究のアプローチ

| アプローチ | 説明 |
|-----------|------|
| **モバイルアプリによる自己記録** | アプリを通じた日々の気分記録による自身の感情への認識向上と精神的ウェルビーイングの向上 |
| **認知行動療法(CBT)ベースの介入** | 認知行動療法に基づくチャットボットとの対話によるうつ病症状の軽減と精神的ウェルビーイングの向上 |

**出典:**
- *Engagement in mobile phone app for self-monitoring of emotional wellbeing predicts changes in mental health: MoodPrism (2018)*
- *Delivering Cognitive Behavior Therapy to Young Adults With Symptoms of Depression and Anxiety Using a Fully Automated Conversational Agent (Woebot): A Randomized Controlled Trial (2017)*

#### 本研究の独自性

- **音声入力による感情分析**
- **感情ダイナミクス**（時系列的な感情パターン分析）
- **心理的ウェルビーイングに着目**

### 音声入力を選択した理由

主観的報告バイアスに影響されない**客観的かつ非侵襲的な感情測定**が可能

#### 従来手法の問題点

- **主観的報告バイアス**: 現在の気分や記憶の歪み、社会的望ましさによる影響
- **心理的負担**: 質問紙への回答や自己内省が必要

#### 音声分析の利点

- **客観的測定**: 音声の韻律情報から、記憶や主観に依存しない感情を測定
- **非侵襲的な測定**: 質問に答える必要がなく心理的負担が少ない

**（出典: Retrospective and Concurrent Self-Reports: The Rationale for Real-Time Data Capture (Schwarz, 2007)）**

### 感情ダイナミクスを扱う理由

#### 理由

感情ダイナミクスは心理的ウェルビーイングの指標となるため

#### 感情ダイナミクスの定義

> 感情ダイナミクスという用語は、秒、時間、または日数といった複数の時点にわたる、人々の感情的および情動的状態の変化と変動を特徴づけるパターンと規則性を指す

**（出典: The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis (2015)）**

### 感情ダイナミクスの構成要素

#### 1. 感情変動性（Affective Variability）

- 感情の揺れ動きの大きさ・範囲
- **測定方法**: iSD（個人内標準偏差）で測定

#### 2. 感情不安定性（Affective Instability）

- 変化の速さ・頻度に焦点
- **測定方法**: MSSD（平均二乗化連続差）で測定

#### 3. 感情慣性（Emotional Inertia）

- 感情状態の持続性・変化しにくさ
- **測定方法**: 自己相関で測定

**（出典: The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis (2015)）**

### 補足① 感情の変動性 (Emotional variability)

**定義**: ある時間における感情状態の範囲または振幅を指す

**計算方法**: 時間を通じた感情状態の個人内標準偏差（SD）として計算

**計算式**:

```
SD = √[Σ(xi - x̄)² / N]
```

- `xi`: 各時点の感情スコア
- `N`: 測定回数
- `x̄`: 全スコアの平均値

**（出典: The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis (2015)）**

### 補足② 感情の不安定性 (Emotional instability)

**定義**: ある瞬間から次のある瞬間への感情変化の大きさを指す

**計算方法**: 連続する感情スコア間の平均二乗化連続差（MSSD）として計算

**計算式**:

```
MSSD = Σ(xi+1 - xi)² / (N - 1)
```

- `xi`: i 回目のスコア
- `xi+1`: i+1 回目のスコア
- `N`: 測定回数

**（出典: The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis (2015)）**

### 補足③ 感情の慣性 (Emotional inertia)

**定義**: ある感情状態が、その直前の感情状態からどれだけうまく予測できるかを指す

**計算方法**: 時間を通じた感情の自己相関（Autocorrelation）として計算

**計算式**:

```
r1 = Σ[(xi - x̄)(xi+1 - x̄)] / Σ(xi - x̄)²
```

- `xi`: i 回目のスコア
- `xi+1`: i+1 回目のスコア
- `N`: 測定回数
- `x̄`: 全スコアの平均値

**（出典: The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis (2015)）**

---

## 3. システム概要

### システムの流れ

**音声入力 → 感情分析 → フィードバック → ウェルビーイング向上**

感情分析には独自の機械学習モデルを構築

### システム構成

```
┌─────────────────────────────────────────────────────────────┐
│                      クライアント層                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           Flutter Mobile App                        │   │
│  │                                                      │   │
│  │    • 音声録音（最大60秒）                              │   │
│  │    • 週次感情グラフ表示                                │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            ↕ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Services                        │
│                                                             │
│    • Firebase Authentication     （認証管理）               │
│    • Cloud Firestore            （感情情報保存）            │
│    • Cloud Storage              （音声保存）                │
│    • Firebase Cloud Messaging   （プッシュ通知）            │
│    • Cloud Functions            （感情分析）                │
│    • Cloud Scheduler            （定期実行）                │
│    • Firebase App Distribution  （アプリ配布）              │
└─────────────────────────────────────────────────────────────┘
```

### 感情分析における機械学習モデル

#### 感情カテゴリ分類

音声に表現される感情の種類（positive, negative, neutral）の特定と離散的なカテゴリへの分類

#### 感情強度回帰

分類されたカテゴリに対する「強さ」や「度合い」の連続的な数値による定量化

---

## 4. 予備実験

### 予備実験の概要

#### 予備実験の目的

音声データから感情（カテゴリと強度）を予測する機械学習モデルの構築とその性能評価

#### 使用したデータセット

**自然対話音声データ（OGVC）**

- 評価者3名による主要感情ラベル
- 評価者18名による感情強度の平均値
- 10クラス分類: `JOY` / `ACC` / `FEA` / `SUR` / `SAD` / `DIS` / `ANG` / `ANT` / `NEU` / `OTH`

### 実験手順

1. **opensmile による特徴量抽出**（ComParE_2016、6,373次元）
2. **ラベル準備と結合**（感情カテゴリ・強度）
3. **データ分割**（8:2、stratified split）
4. **特徴量選択・欠損値補完**（SelectKBest、上位500特徴量）
5. **GridSearchCV によるパラメータ最適化**
6. **テストデータでの評価・モデル保存**

### 補足④ opensmile による特徴量抽出

#### 特徴量抽出の概要

| 項目 | 内容 |
|------|------|
| **目的** | 音声信号の物理特性を定量化し、感情に関連する特徴ベクトルを生成 |
| **使用ライブラリ** | opensmile 2.6.0（音声信号処理の標準ツール） |
| **FeatureSet** | ComParE_2016（音声感情認識で広く使用される標準的な特徴量セット） |
| **FeatureLevel** | Functionals（音声セグメント全体の統計量：平均、標準偏差など） |
| **次元数** | 6,373次元（各音声ファイルにつき1つの特徴ベクトル） |

### 補足⑤ 特徴量選択・欠損値補完

#### 特徴量選択

- **目的**: 高次元特徴量から目的変数との関連性が高い特徴を選択
- **手法**: SelectKBest で上位500特徴量を選択
- **スコアリング**: 
  - 分類: `f_classif`
  - 回帰: `f_regression`

#### 欠損値補完

- **目的**: 特徴量抽出過程で発生した欠損値(NaN)を適切な値で置換
- **手法**: `SimpleImputer(strategy='mean')` — 各特徴量の平均値で補完

### 補足⑥ GridSearchCV によるパラメータ最適化

GridSearchCV による交差検証でパラメータ最適化

#### 感情カテゴリ分類

- `n_estimators`: 200（ブースティング回数）
- `learning_rate`: 0.1（学習率）
- `max_depth`: 7（木の深さ）

#### 感情強度回帰

- `n_estimators`: 200（ブースティング回数）
- `learning_rate`: 0.1（学習率）
- `max_depth`: 7（木の深さ）

### 実験結果（性能評価）

#### 【感情カテゴリ分類（XGBoost Classifier）】

**総合精度（Accuracy）: 0.78**

| クラス | Precision | Recall | F1-score |
|--------|-----------|--------|----------|
| **negative** | 0.89 | 0.78 | 0.83 |
| **neutral** | 0.73 | 0.56 | 0.63 |
| **positive** | 0.73 | 0.89 | 0.80 |

#### 【感情強度回帰（XGBoost Regressor）】

**MSE: 0.0059**

### 実験結果（混同行列）

#### 混同行列の分析

- **positive クラス**: True positive が 113 と高く、誤分類も少ない
- **negative クラス**: True negative が 75 と良好、全体的に識別性能が高い
- **neutral クラス**: 正確に識別できたのは 37 のみ、特に positive と誤分類(26)されやすい

### 結果に対する考察

#### 感情カテゴリ分類

- **総合精度**: Accuracy 0.78
- **F1-score**: 
  - positive: 0.80
  - neutral: 0.63
  - negative: 0.83

#### 感情強度回帰

- **予測精度**: MSE 0.0059（予測誤差が非常に小さい）

#### 結論

✅ **本実験に使用可能な十分な精度を確認**

neutral の識別精度に課題は残るものの、positive, negative の識別精度とその強度の予測精度より、システムの根幹である**感情ダイナミクスの算出は可能**

---

## 5. 今後の予定

### 本実験概要

#### 目的

ウェルビーイングに対する**システムの有効性**を検証

#### 本実験手順

1. **事前評価** — 質問紙調査（PWB）
2. **ベースライン期** — 7日間の音声データ収集、フィードバックなし
3. **介入期** — 3日間の音声データ収集、フィードバックあり
4. **事後評価** — 質問紙再実施、体験インタビューによる評価

---

## まとめ

✓ **ウェルビーイングとは**  
WHO憲章による健康の定義に含まれる幸福状態を指す

✓ **音声から得た感情ダイナミクスを利用したウェルビーイングの向上システムを開発**

✓ **予備実験によりシステムの根幹である感情ダイナミクスの算出可能性を確認**

→ **今後の展望として本実験によりウェルビーイングに対するシステムの有効性を検証**

---

## 参考文献

1. World Health Organization (WHO). WHO憲章
2. World Economic Forum (WEF). Thriving Workplaces レポート (2025)
3. Gallup. 従業員エンゲージメント研究 (2019)
4. World Health Organization (WHO). メンタルヘルス職場ガイドライン (2022)
5. Deloitte. 健康平等性の経済効果分析 (2040年予測)
6. Houben, M., et al. (2015). The Relation Between Short-Term Emotion Dynamics and Psychological Well-Being: A Meta-Analysis. *Psychological Bulletin*, 141(4), 901-930.
7. Bakker, D., et al. (2018). Engagement in mobile phone app for self-monitoring of emotional wellbeing predicts changes in mental health: MoodPrism. *Journal of Affective Disorders*, 227, 432-442.
8. Fitzpatrick, K. K., et al. (2017). Delivering Cognitive Behavior Therapy to Young Adults With Symptoms of Depression and Anxiety Using a Fully Automated Conversational Agent (Woebot): A Randomized Controlled Trial. *JMIR Mental Health*, 4(2), e19.
9. Schwarz, N. (2007). Retrospective and Concurrent Self-Reports: The Rationale for Real-Time Data Capture. In A. Stone et al. (Eds.), *The Science of Real-Time Data Capture: Self-Reports in Health Research* (pp. 11-26). Oxford University Press.

