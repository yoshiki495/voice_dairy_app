import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/sample_data_service.dart';

// 認証状態を管理するプロバイダー（サンプル実装）
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // アプリ起動時に自動的にサンプルユーザーでログイン
    _autoLogin();
  }

  void _autoLogin() {
    state = state.copyWith(isLoading: true);
    
    // 実際の実装では Firebase Auth を使用
    // ここではサンプルデータを使用
    Future.delayed(const Duration(seconds: 1), () {
      state = state.copyWith(
        user: SampleDataService.sampleUser,
        isLoading: false,
      );
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 実際の実装では Firebase Auth を使用
      await Future.delayed(const Duration(seconds: 1));
      
      // サンプル実装: どんなメール・パスワードでもログイン成功
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'ログインに失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 実際の実装では Firebase Auth を使用
      await Future.delayed(const Duration(seconds: 1));
      
      // サンプル実装: 自動的にアカウント作成成功
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'アカウント作成に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    // 実際の実装では Firebase Auth を使用
    await Future.delayed(const Duration(milliseconds: 500));
    
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
