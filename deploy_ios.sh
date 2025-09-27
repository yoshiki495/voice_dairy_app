#!/bin/bash

# Voice Diary App - iOS Deployment Script
# Firebase App Distribution を使用したiOSアプリ配布スクリプト

set -e  # エラー時に終了

# 設定
PROJECT_ID="voice-dairy-app-70a9d"
IOS_APP_ID="1:354933216254:ios:8db0424cc99dcb368126af"
TESTER_GROUP="testers"
APP_NAME="Voice Diary App"

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

echo "🚀 Voice Diary App - iOS デプロイスクリプト"
echo "============================================="
echo "📱 配布方法: Firebase App Distribution"
echo "💰 コスト: 無料"
echo ""

# 前提条件チェック
print_step "前提条件チェック"

# Flutter確認
if ! command -v flutter &> /dev/null; then
    print_error "Flutterがインストールされていません"
    exit 1
fi
print_success "Flutter確認完了"

# Firebase CLI確認
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLIがインストールされていません"
    echo "インストール方法: npm install -g firebase-tools"
    exit 1
fi
print_success "Firebase CLI確認完了"

# Xcode確認
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcodeがインストールされていません"
    exit 1
fi
print_success "Xcode確認完了"

# Firebase認証確認
if ! firebase projects:list &> /dev/null; then
    print_error "Firebaseにログインしていません"
    echo "実行コマンド: firebase login"
    exit 1
fi
print_success "Firebase認証確認完了"

# プロジェクト設定確認
print_step "プロジェクト設定確認"
firebase use $PROJECT_ID
print_success "Firebaseプロジェクト設定完了: $PROJECT_ID"

# 必要ファイル確認
required_files=(
    "ios/Runner/GoogleService-Info.plist"
    "pubspec.yaml"
    "ios/Runner.xcworkspace"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ] && [ ! -d "$file" ]; then
        print_error "必要なファイル/ディレクトリが見つかりません: $file"
        exit 1
    fi
done
print_success "必要ファイル確認完了"

# バージョン情報取得
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
print_step "アプリバージョン: $VERSION"

# リリースノート入力
echo ""
read -p "📝 リリースノートを入力してください (Enter で既定値): " RELEASE_NOTES
if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="Voice Diary App v$VERSION - $(date '+%Y年%m月%d日') リリース"
fi

echo ""
echo "🎯 デプロイ情報:"
echo "  📱 アプリ: $APP_NAME"
echo "  📦 バージョン: $VERSION"
echo "  📝 リリースノート: $RELEASE_NOTES"
echo "  👥 配布先: $TESTER_GROUP グループ"
echo ""

read -p "デプロイを開始しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "デプロイをキャンセルしました"
    exit 0
fi

# 1. 依存関係の更新
print_step "依存関係の更新"
flutter pub get
cd ios && pod install && cd ..
print_success "依存関係更新完了"

# 2. クリーンビルド
print_step "クリーンビルド実行"
flutter clean
print_success "クリーンビルド完了"

# 3. IPAファイルの作成
print_step "IPAファイルの作成"
if flutter build ipa --release; then
    print_success "IPAファイル作成完了"
    IPA_PATH="build/ios/ipa/voice_dairy_app.ipa"
else
    print_warning "自動ビルドに失敗しました。Xcodeでの手動ビルドが必要です。"
    echo ""
    echo "📋 手動ビルド手順:"
    echo "1. open ios/Runner.xcworkspace"
    echo "2. Product → Archive"
    echo "3. Distribute App → Ad Hoc"
    echo "4. IPAファイルをエクスポート"
    echo ""
    read -p "手動でIPAファイルを作成しましたか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "IPAファイルが必要です。デプロイを中止します。"
        exit 1
    fi
    
    # 手動ビルドの場合、IPAファイルのパスを入力してもらう
    read -p "IPAファイルのパスを入力してください: " IPA_PATH
    if [ ! -f "$IPA_PATH" ]; then
        print_error "指定されたIPAファイルが見つかりません: $IPA_PATH"
        exit 1
    fi
fi

# 4. Firebase App Distributionにアップロード
print_step "Firebase App Distributionにアップロード"
if firebase appdistribution:distribute "$IPA_PATH" \
    --app "$IOS_APP_ID" \
    --groups "$TESTER_GROUP" \
    --release-notes "$RELEASE_NOTES"; then
    print_success "Firebase App Distributionアップロード完了"
else
    print_error "Firebase App Distributionアップロードに失敗しました"
    exit 1
fi

# 5. 配布完了メッセージ
echo ""
echo "🎉 iOS アプリ配布完了！"
echo "=========================="
echo ""
echo "📋 配布情報:"
echo "  ✅ アプリ: $APP_NAME"
echo "  ✅ バージョン: $VERSION"
echo "  ✅ 配布方法: Firebase App Distribution"
echo "  ✅ 対象グループ: $TESTER_GROUP"
echo ""
echo "🌐 管理URL:"
echo "  📊 Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID/appdistribution"
echo ""
echo "👥 テスター向け手順:"
echo "  1. 招待メールのリンクをクリック"
echo "  2. Firebase App Distribution アプリをインストール"
echo "     App Store: https://apps.apple.com/app/firebase-app-distribution/id1477792118"
echo "  3. Voice Diary App をダウンロード・インストール"
echo ""
echo "⚠️  重要な注意事項:"
echo "  • アプリの有効期限: 90日（再配布で延長可能）"
echo "  • テスターは招待されたメールアドレスでのみアクセス可能"
echo "  • 「信頼されていない開発者」エラーが出た場合:"
echo "    設定 → 一般 → VPNとデバイス管理 → 開発者プロファイルを信頼"
echo ""
echo "🔄 次回更新時:"
echo "  1. pubspec.yaml のバージョン番号を更新"
echo "  2. 再度このスクリプトを実行"
echo ""
