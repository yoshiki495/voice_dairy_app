import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

// Firebase Auth を使用した認証状態管理
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
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthNotifier(this._firebaseAuth, this._firestore) : super(const AuthState()) {
    // Firebase Auth の状態変化を監視
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      state = const AuthState();
      return;
    }

    try {
      // Firestore からユーザー情報を取得
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      User? user;
      if (userDoc.exists) {
        final data = userDoc.data()!;
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      } else {
        // Firestore にユーザー情報がない場合は作成
        user = User(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'email': user.email,
          'createdAt': Timestamp.fromDate(user.createdAt),
        });
      }

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'ユーザー情報の取得に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 状態の更新は authStateChanges() で自動的に行われる
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'このメールアドレスのアカウントが見つかりません';
          break;
        case 'wrong-password':
          errorMessage = 'パスワードが間違っています';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません';
          break;
        case 'user-disabled':
          errorMessage = 'このアカウントは無効化されています';
          break;
        case 'too-many-requests':
          errorMessage = 'ログイン試行回数が多すぎます。しばらく待ってから再試行してください';
          break;
        default:
          errorMessage = 'ログインに失敗しました: ${e.message}';
      }
      state = state.copyWith(error: errorMessage, isLoading: false);
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
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 状態の更新は authStateChanges() で自動的に行われる
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'パスワードが弱すぎます';
          break;
        case 'email-already-in-use':
          errorMessage = 'このメールアドレスは既に使用されています';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません';
          break;
        case 'operation-not-allowed':
          errorMessage = 'メール・パスワード認証が無効化されています';
          break;
        default:
          errorMessage = 'アカウント作成に失敗しました: ${e.message}';
      }
      state = state.copyWith(error: errorMessage, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'アカウント作成に失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _firebaseAuth.signOut();
      // 状態の更新は authStateChanges() で自動的に行われる
    } catch (e) {
      state = state.copyWith(
        error: 'ログアウトに失敗しました: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'このメールアドレスのアカウントが見つかりません';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません';
          break;
        default:
          errorMessage = 'パスワードリセットに失敗しました: ${e.message}';
      }
      throw Exception(errorMessage);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Firebase Auth と Firestore のインスタンスを提供するプロバイダー
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>((ref) {
  return firebase_auth.FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  final firestore = ref.read(firestoreProvider);
  return AuthNotifier(firebaseAuth, firestore);
});
