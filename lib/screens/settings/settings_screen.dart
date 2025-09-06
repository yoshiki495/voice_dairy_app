import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ListView(
        children: [
          // ユーザー情報セクション
          _buildSection(
            title: 'アカウント情報',
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    authState.user?.email.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(authState.user?.email ?? ''),
                subtitle: const Text('Firebase認証ユーザー'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // プロフィール編集画面へ（将来実装）
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('プロフィール編集機能は今後実装予定です'),
                    ),
                  );
                },
              ),
            ],
          ),

          // 通知設定セクション
          _buildSection(
            title: '通知設定',
            children: [
              SwitchListTile(
                title: const Text('プッシュ通知'),
                subtitle: const Text('毎日の録音リマインダーを受け取る'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  // 実際の実装では通知設定を保存
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('通知時刻'),
                subtitle: Text(
                  '${_notificationTime.hour.toString().padLeft(2, '0')}:${_notificationTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: _notificationsEnabled,
                onTap: _notificationsEnabled ? _selectNotificationTime : null,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('通知について'),
                subtitle: const Text('現在はサンプル実装のため、実際の通知は送信されません'),
                enabled: false,
              ),
            ],
          ),

          // アプリ設定セクション
          _buildSection(
            title: 'アプリ設定',
            children: [
              SwitchListTile(
                title: const Text('ダークモード'),
                subtitle: const Text('アプリの外観を暗いテーマに変更'),
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // 実際の実装ではテーマ設定を保存
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ダークモード切り替え機能は今後実装予定です'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('言語'),
                subtitle: const Text('日本語'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('言語設定機能は今後実装予定です'),
                    ),
                  );
                },
              ),
            ],
          ),

          // データ管理セクション
          _buildSection(
            title: 'データ管理',
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('データをエクスポート'),
                subtitle: const Text('録音データと感情スコアをダウンロード'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showExportDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('全データを削除', style: TextStyle(color: Colors.red)),
                subtitle: const Text('すべての録音データと感情スコアを削除'),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () {
                  _showDeleteDataDialog();
                },
              ),
            ],
          ),

          // サポートセクション
          _buildSection(
            title: 'サポート',
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('ヘルプ'),
                subtitle: const Text('アプリの使い方'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showHelpDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('フィードバック'),
                subtitle: const Text('ご意見・ご要望をお聞かせください'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('フィードバック機能は今後実装予定です'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('アプリについて'),
                subtitle: const Text('バージョン 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showAboutDialog();
                },
              ),
            ],
          ),

          // ログアウトボタン
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: authState.isLoading ? null : () {
                _showLogoutDialog();
              },
              icon: authState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: Text(authState.isLoading ? 'ログアウト中...' : 'ログアウト'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });
      // 実際の実装では通知時刻を保存
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データエクスポート'),
        content: const Text(
          'データエクスポート機能は現在開発中です。\n'
          '将来的には、録音データと感情スコアをJSON形式で\n'
          'エクスポートできるようになります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データ削除'),
        content: const Text(
          'すべてのデータを削除しますか？\n'
          'この操作は元に戻せません。\n\n'
          '※ 現在はサンプル実装のため、実際のデータ削除は行われません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('データ削除機能は今後実装予定です'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘルプ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '音声日記アプリの使い方',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. 毎日20時に通知が届きます'),
              Text('2. 録音ボタンをタップして音声を録音'),
              Text('3. 最大60秒まで自由に話せます'),
              Text('4. AIが感情スコアを解析します'),
              Text('5. 週次グラフで感情の変化を確認'),
              SizedBox(height: 16),
              Text(
                '注意事項',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Firebase認証が実装済みです'),
              Text('• 音声解析機能は今後実装予定'),
              Text('• ユーザーデータはFirestoreに保存'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '音声日記',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.mic, size: 48),
      children: const [
        Text(
          '毎日の感情を音声で記録し、\n'
          'AIが解析した感情スコアで\n'
          '心の変化を可視化するアプリです。',
        ),
        SizedBox(height: 16),
        Text(
          'Firebase認証機能が実装済みです。\n'
          '音声録音・解析、プッシュ通知機能は\n'
          '今後実装予定です。',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
