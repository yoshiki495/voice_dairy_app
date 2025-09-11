import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class ProfileDetailModal extends ConsumerWidget {
  final User user;

  const ProfileDetailModal({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('アカウント情報'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            context,
            icon: Icons.email,
            label: 'メールアドレス',
            value: user.email,
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            context,
            icon: Icons.calendar_today,
            label: '登録日',
            value: DateFormat('yyyy年MM月dd日').format(user.createdAt),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            context,
            icon: Icons.access_time,
            label: '利用期間',
            value: _getUsageDuration(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getUsageDuration() {
    final now = DateTime.now();
    final duration = now.difference(user.createdAt);
    
    if (duration.inDays >= 365) {
      final years = (duration.inDays / 365).floor();
      return '${years}年';
    } else if (duration.inDays >= 30) {
      final months = (duration.inDays / 30).floor();
      return '${months}ヶ月';
    } else if (duration.inDays > 0) {
      return '${duration.inDays}日';
    } else {
      return '今日登録';
    }
  }
}