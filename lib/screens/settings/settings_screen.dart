import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/mood_provider.dart';
import '../../services/firestore_sample_data_service.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/profile_detail_modal.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeState = ref.watch(themeProvider);

    return SwipeableScaffold(
      onSwipeBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      appBar: SwipeableAppBar(
        title: '設定',
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
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
                subtitle: const Text('ログイン中'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (authState.user != null) {
                    _showProfileDetailModal(authState.user!);
                  }
                },
              ),
            ],
          ),

          // 表示設定セクション
          _buildSection(
            title: '表示設定',
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('テーマ'),
                subtitle: Text(themeState.themeOption.displayName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(),
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

          // 開発者向けセクション
          _buildSection(
            title: '開発者向け',
            children: [
              ListTile(
                leading: const Icon(Icons.add_chart),
                title: const Text('サンプルデータを追加'),
                subtitle: const Text('10日分のサンプルデータをFirestoreに追加'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _addSampleData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('サンプルデータを削除'),
                subtitle: const Text('サンプルデータのみを削除'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _clearSampleData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('すべてのデータを削除', style: TextStyle(color: Colors.red)),
                subtitle: const Text('すべての感情データを削除'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _clearAllData();
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
              Text('• 現在はサンプル実装です'),
              Text('• 実際の音声解析は未実装'),
              Text('• データは永続化されません'),
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

  void _showThemeDialog() {
    final themeState = ref.read(themeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テーマ選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeOption.values.map((option) {
            return RadioListTile<ThemeOption>(
              title: Text(option.displayName),
              subtitle: _getThemeDescription(option),
              value: option,
              groupValue: themeState.themeOption,
              onChanged: (ThemeOption? value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setTheme(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget? _getThemeDescription(ThemeOption option) {
    switch (option) {
      case ThemeOption.system:
        return const Text('端末の設定に合わせて自動で変更されます');
      case ThemeOption.light:
        return const Text('明るい背景色で表示されます');
      case ThemeOption.dark:
        return const Text('暗い背景色で表示されます');
    }
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
          '現在はサンプル実装版です。\n'
          'ユーザー認証、音声録音・解析、\n'
          'プッシュ通知機能は今後実装予定です。',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showProfileDetailModal(User user) {
    showDialog(
      context: context,
      builder: (context) => ProfileDetailModal(user: user),
    );
  }

  Future<void> _addSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サンプルデータを追加'),
        content: const Text('今日から10日前から10日分のサンプルデータをFirestoreに追加します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final service = FirestoreSampleDataService();
      await service.addSampleData();

      // データをリロード
      await ref.read(moodProvider.notifier).loadMoodData();

      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サンプルデータを追加しました')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _clearSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サンプルデータを削除'),
        content: const Text('サンプルデータのみを削除します。よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final service = FirestoreSampleDataService();
      await service.clearSampleData();

      // データをリロード
      await ref.read(moodProvider.notifier).loadMoodData();

      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('サンプルデータを削除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('すべてのデータを削除', style: TextStyle(color: Colors.red)),
        content: const Text('すべての感情データを削除します。この操作は取り消せません。本当によろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final service = FirestoreSampleDataService();
      await service.clearAllMoodData();

      // データをリロード
      await ref.read(moodProvider.notifier).loadMoodData();

      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのデータを削除しました')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }
}
