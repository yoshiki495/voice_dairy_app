import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import '../../providers/mood_provider.dart';

enum RecordingState {
  idle,
  recording,
  completed,
  processing,
}

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with TickerProviderStateMixin {
  RecordingState _recordingState = RecordingState.idle;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  static const int maxRecordingDuration = 60; // 60秒
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // パルスアニメーション
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // 波形アニメーション
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startRecording() async {
    setState(() {
      _recordingState = RecordingState.recording;
      _recordingDuration = 0;
    });

    // アニメーション開始
    _pulseController.repeat();
    _waveController.repeat();

    // 録音タイマー開始
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });

      if (_recordingDuration >= maxRecordingDuration) {
        _stopRecording();
      }
    });

    // 実際の録音処理は将来実装
    // await record.start();
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    setState(() {
      _recordingState = RecordingState.completed;
    });

    // 実際の録音停止処理は将来実装
    // await record.stop();
  }

  void _processRecording() async {
    setState(() {
      _recordingState = RecordingState.processing;
    });

    try {
      // ランダムなスコアを生成（実際の実装では音声解析結果を使用）
      final random = Random();
      final score = (random.nextDouble() * 2.0) - 1.0;
      
      // サンプル実装: 感情スコアを保存
      await ref.read(moodProvider.notifier).addMoodEntry(score);
      
      // 結果を表示
      if (mounted) {
        _showResultDialog(score);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理エラー: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _recordingState = RecordingState.idle;
      });
    }
  }

  void _showResultDialog(double score) {
    final label = score >= 0.5 
        ? 'ポジティブ' 
        : score <= -0.5 
            ? 'ネガティブ' 
            : 'ニュートラル';
    
    final emoji = score >= 0.5 
        ? '😊' 
        : score <= -0.5 
            ? '😢' 
            : '😐';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('解析完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'スコア: ${score.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '感情: $label',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('今日の音声日記を記録しました！'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }

  void _resetRecording() {
    setState(() {
      _recordingState = RecordingState.idle;
      _recordingDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('音声録音'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _recordingState == RecordingState.recording || 
                     _recordingState == RecordingState.processing
              ? null
              : () => context.go('/home'),
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 録音状態表示
            Text(
              _getStatusText(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // タイマー表示
            if (_recordingState == RecordingState.recording) ...[
              Text(
                _formatDuration(_recordingDuration),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '残り ${_formatDuration(maxRecordingDuration - _recordingDuration)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
            ] else if (_recordingState == RecordingState.completed) ...[
              Text(
                '録音時間: ${_formatDuration(_recordingDuration)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // 録音ボタンエリア
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // パルスエフェクト
                  if (_recordingState == RecordingState.recording)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 160 + (_pulseAnimation.value * 40),
                          height: 160 + (_pulseAnimation.value * 40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.3 - (_pulseAnimation.value * 0.3)),
                          ),
                        );
                      },
                    ),
                  
                  // 波形エフェクト
                  if (_recordingState == RecordingState.recording)
                    AnimatedBuilder(
                      animation: _waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(200, 50),
                          painter: WaveformPainter(_waveAnimation.value),
                        );
                      },
                    ),

                  // メイン録音ボタン
                  GestureDetector(
                    onTap: _getButtonAction(),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getButtonColor(),
                        boxShadow: [
                          BoxShadow(
                            color: _getButtonColor().withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getButtonIcon(),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 説明テキスト
            Text(
              _getInstructionText(),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // アクションボタン
            if (_recordingState == RecordingState.completed) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetRecording,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再録音'),
                  ),
                  ElevatedButton.icon(
                    onPressed: moodState.isLoading ? null : _processRecording,
                    icon: moodState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(moodState.isLoading ? '処理中...' : '送信'),
                  ),
                ],
              ),
            ],

            if (_recordingState == RecordingState.processing) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('音声を解析中...'),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_recordingState) {
      case RecordingState.idle:
        return '今日の気持ちを話してみましょう';
      case RecordingState.recording:
        return '録音中...';
      case RecordingState.completed:
        return '録音完了！';
      case RecordingState.processing:
        return '解析中...';
    }
  }

  String _getInstructionText() {
    switch (_recordingState) {
      case RecordingState.idle:
        return '録音ボタンをタップして、今日の出来事や気持ちを自由に話してください。\n最大60秒まで録音できます。';
      case RecordingState.recording:
        return '自由に話してください。もう一度タップすると録音を停止します。';
      case RecordingState.completed:
        return '録音が完了しました。再録音または送信を選択してください。';
      case RecordingState.processing:
        return 'AIが音声を解析して感情スコアを算出しています...';
    }
  }

  VoidCallback? _getButtonAction() {
    switch (_recordingState) {
      case RecordingState.idle:
        return _startRecording;
      case RecordingState.recording:
        return _stopRecording;
      case RecordingState.completed:
      case RecordingState.processing:
        return null;
    }
  }

  Color _getButtonColor() {
    switch (_recordingState) {
      case RecordingState.idle:
        return Theme.of(context).primaryColor;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.completed:
        return Colors.green;
      case RecordingState.processing:
        return Colors.grey;
    }
  }

  IconData _getButtonIcon() {
    switch (_recordingState) {
      case RecordingState.idle:
        return Icons.mic;
      case RecordingState.recording:
        return Icons.stop;
      case RecordingState.completed:
        return Icons.check;
      case RecordingState.processing:
        return Icons.hourglass_empty;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// 波形を描画するCustomPainter
class WaveformPainter extends CustomPainter {
  final double animationValue;

  WaveformPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final waveCount = 5;
    
    for (int i = 0; i < waveCount; i++) {
      final x = (size.width / waveCount) * i;
      final height = sin((animationValue * 2 * pi) + (i * 0.5)) * 20;
      
      if (i == 0) {
        path.moveTo(x, size.height / 2 + height);
      } else {
        path.lineTo(x, size.height / 2 + height);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
