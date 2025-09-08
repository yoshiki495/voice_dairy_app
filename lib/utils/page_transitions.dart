import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// カスタムページトランジション
class CustomPageTransition {
  /// iOS風のスライドトランジション（戻る動作を考慮）
  static CustomTransitionPage<T> slideTransition<T extends Object?>(
    Widget child,
    GoRouterState state, {
    bool isFromRight = true,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        
        // 進む時：右から左へ
        // 戻る時：左から右へ（iOSの標準動作）
        final begin = isFromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
        const end = Offset.zero;
        
        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        // セカンダリアニメーション：前の画面が同時に動く
        final secondaryEnd = isFromRight ? const Offset(-0.3, 0.0) : const Offset(0.3, 0.0);
        var secondaryTween = Tween(begin: Offset.zero, end: secondaryEnd).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: SlideTransition(
            position: secondaryAnimation.drive(secondaryTween),
            child: child,
          ),
        );
      },
    );
  }

  /// 左からスライドインするトランジション（戻る時）
  static CustomTransitionPage<T> slideFromLeft<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return slideTransition(child, state, isFromRight: false);
  }

  /// 右からスライドインするトランジション（進む時）
  static CustomTransitionPage<T> slideFromRight<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return slideTransition(child, state, isFromRight: true);
  }

  /// フェードトランジション
  static CustomTransitionPage<T> fade<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// スケールトランジション（モーダル風）
  static CustomTransitionPage<T> scale<T extends Object?>(
    Widget child,
    GoRouterState state,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOutBack;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

/// スワイプジェスチャーを処理するウィジェット
class SwipeNavigationWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeBack;
  final bool enableSwipeBack;
  final double swipeThreshold;
  final double velocityThreshold;

  const SwipeNavigationWrapper({
    super.key,
    required this.child,
    this.onSwipeBack,
    this.enableSwipeBack = true,
    this.swipeThreshold = 100.0, // 100ピクセル以上スワイプ
    this.velocityThreshold = 300.0, // 300以上の速度
  });

  @override
  State<SwipeNavigationWrapper> createState() => _SwipeNavigationWrapperState();
}

class _SwipeNavigationWrapperState extends State<SwipeNavigationWrapper>
    with TickerProviderStateMixin {
  double _dragStartX = 0.0;
  bool _isDragging = false;
  double _dragOffset = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableSwipeBack || widget.onSwipeBack == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedOffset = _isDragging ? _dragOffset : _animation.value * _dragOffset;
        return Transform.translate(
          offset: Offset(animatedOffset * 0.3, 0), // スワイプ中の微妙な移動
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              _dragStartX = details.localPosition.dx;
              _isDragging = true;
              _animationController.stop();
            },
            onHorizontalDragUpdate: (details) {
              if (!_isDragging) return;
              
              // 画面左端から開始されたスワイプのみ受け付ける
              final screenWidth = MediaQuery.of(context).size.width;
              if (_dragStartX > screenWidth * 0.2) {
                _isDragging = false;
                return;
              }

              setState(() {
                _dragOffset = (details.localPosition.dx - _dragStartX).clamp(0.0, widget.swipeThreshold);
              });
            },
            onHorizontalDragEnd: (details) {
              if (!_isDragging) return;
              _isDragging = false;

              final dragDistance = details.localPosition.dx - _dragStartX;
              final velocity = details.primaryVelocity ?? 0.0;

              // 右方向にスワイプした場合（戻る操作）
              if ((dragDistance > widget.swipeThreshold && velocity > -widget.velocityThreshold) || 
                  velocity > widget.velocityThreshold) {
                widget.onSwipeBack!();
              } else {
                // スワイプが完了しなかった場合、元の位置に戻る
                _animationController.reverse().then((_) {
                  setState(() {
                    _dragOffset = 0.0;
                  });
                });
              }
            },
            onHorizontalDragCancel: () {
              _isDragging = false;
              _animationController.reverse().then((_) {
                setState(() {
                  _dragOffset = 0.0;
                });
              });
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// スワイプナビゲーション付きAppBar
class SwipeableAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;
  final bool enableSwipeBack;

  const SwipeableAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onBack,
    this.automaticallyImplyLeading = true,
    this.enableSwipeBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeNavigationWrapper(
      enableSwipeBack: enableSwipeBack,
      onSwipeBack: onBack,
      child: AppBar(
        title: Text(title),
        actions: actions,
        leading: leading ??
            (automaticallyImplyLeading && onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: onBack,
                  )
                : null),
        automaticallyImplyLeading: automaticallyImplyLeading && leading == null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// ページ全体をスワイプナビゲーションでラップするウィジェット
class SwipeableScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final VoidCallback? onSwipeBack;
  final bool enableSwipeBack;

  const SwipeableScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.onSwipeBack,
    this.enableSwipeBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwipeNavigationWrapper(
      enableSwipeBack: enableSwipeBack,
      onSwipeBack: onSwipeBack,
      child: Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
    );
  }
}
