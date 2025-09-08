#!/bin/bash

set -e  # エラー時に終了

echo "🚀 Voice Diary App - 全体デプロイスクリプト"
echo "=========================================="

# 色付きメッセージ用の関数
print_step() {
    echo -e "\n\033[1;34m▶ $1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✅ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m❌ $1\033[0m"
}

print_warning() {
    echo -e "\033[1;33m⚠️ $1\033[0m"
}

# 前提条件チェック
print_step "前提条件チェック"

# Firebase CLI確認
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLIがインストールされていません"
    echo "インストール方法: npm install -g firebase-tools"
    exit 1
fi
print_success "Firebase CLI確認完了"

# Google Cloud CLI確認
if ! command -v gcloud &> /dev/null; then
    print_error "Google Cloud CLIがインストールされていません"
    echo "インストール方法: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
print_success "Google Cloud CLI確認完了"

# 認証状態確認
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "Google Cloudにログインしていません"
    echo "実行コマンド: gcloud auth login"
    exit 1
fi
print_success "Google Cloud認証確認完了"

# プロジェクトID確認
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    print_error "Google Cloudプロジェクトが設定されていません"
    echo "実行コマンド: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi
print_success "プロジェクトID: $PROJECT_ID"

# 必要ファイル確認
print_step "必要ファイル存在確認"

required_files=(
    "firebase.json"
    "firestore.rules"
    "storage.rules"
    "cloud_run/main.py"
    "cloud_run/requirements.txt"
    "cloud_run/Dockerfile"
    "cloud_run/deploy.sh"
    "cloud_run/models/best_emotion_classifier_pipeline.pkl"
    "cloud_run/models/best_emotion_regressor_pipeline.pkl"
    "cloud_run/models/label_encoder.pkl"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "必要なファイルが見つかりません: $file"
        exit 1
    fi
done
print_success "必要ファイル確認完了"

# デプロイ開始
echo ""
echo "🎯 デプロイターゲット:"
echo "  - Firebase Firestore ルール"
echo "  - Firebase Storage ルール"
echo "  - Cloud Run API"
echo ""

read -p "デプロイを開始しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "デプロイをキャンセルしました"
    exit 0
fi

# 1. Firebase Firestore ルールのデプロイ
print_step "Firebase Firestore ルールデプロイ"
if firebase deploy --only firestore:rules; then
    print_success "Firestore ルールデプロイ完了"
else
    print_error "Firestore ルールデプロイに失敗しました"
    exit 1
fi

# 2. Firebase Storage ルールのデプロイ
print_step "Firebase Storage ルールデプロイ"
if firebase deploy --only storage; then
    print_success "Storage ルールデプロイ完了"
else
    print_error "Storage ルールデプロイに失敗しました"
    exit 1
fi

# 3. Cloud Run APIのデプロイ
print_step "Cloud Run APIデプロイ"
cd cloud_run
if chmod +x deploy.sh && ./deploy.sh; then
    print_success "Cloud Run APIデプロイ完了"
else
    print_error "Cloud Run APIデプロイに失敗しました"
    exit 1
fi
cd ..

# 4. デプロイ後の動作確認
print_step "デプロイ後動作確認"

# Cloud Run APIヘルスチェック
API_URL="https://voice-emotion-analysis-354933216254.asia-northeast1.run.app/health"
print_step "Cloud Run APIヘルスチェック"
if curl -s "$API_URL" | grep -q "healthy"; then
    print_success "Cloud Run API正常稼働中"
else
    print_warning "Cloud Run APIヘルスチェックに異常がある可能性があります"
    echo "URL: $API_URL"
fi

# Flutter アプリ分析
print_step "Flutter アプリ静的解析"
if flutter analyze; then
    print_success "Flutter 静的解析 PASS"
else
    print_warning "Flutter 静的解析で警告がありました"
fi

# 完了メッセージ
echo ""
echo "🎉 全体デプロイ完了！"
echo "==============================="
echo ""
echo "📋 デプロイ結果:"
echo "  ✅ Firebase Firestore ルール"
echo "  ✅ Firebase Storage ルール"  
echo "  ✅ Cloud Run API"
echo ""
echo "🌐 本番環境URL:"
echo "  📱 Cloud Run API: https://voice-emotion-analysis-354933216254.asia-northeast1.run.app"
echo "  🔧 Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
echo "🧪 次のステップ:"
echo "  1. Flutterアプリでの動作確認"
echo "  2. 音声録音→感情分析の全フロー確認"
echo "  3. 必要に応じて本番リリース準備"
echo ""
