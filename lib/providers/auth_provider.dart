import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/firebase_auth_service.dart';

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
  final FirebaseAuthService _authService = FirebaseAuthService();

  AuthNotifier() : super(const AuthState()) {
    // Firebase認証状態の変更を監視
    _authService.authStateChanges.listen((firebase_auth.User? user) {
      if (user != null) {
        final appUser = User(
          id: user.uid,
          email: user.email ?? '',
          createdAt: user.metadata.creationTime ?? DateTime.now(),
        );
        state = state.copyWith(user: appUser, isLoading: false);
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      // 認証状態の変更は authStateChanges で自動的に処理される
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.createUserWithEmailAndPassword(email, password);
      // 認証状態の変更は authStateChanges で自動的に処理される
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _authService.signOut();
      // 認証状態の変更は authStateChanges で自動的に処理される
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
