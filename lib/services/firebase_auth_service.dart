import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Firebase UserをアプリのUserモデルに変換
  app_user.User? _userFromFirebase(User? user) {
    if (user == null) return null;
    
    return app_user.User(
      id: user.uid,
      email: user.email ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  // メールアドレスとパスワードでサインイン
  Future<app_user.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // メールアドレスとパスワードでアカウント作成
  Future<app_user.User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(result.user);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // サインアウト
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('サインアウトに失敗しました: ${e.toString()}');
    }
  }

  // パスワードリセットメール送信
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Firebase認証エラーを日本語メッセージに変換
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'このメールアドレスのアカウントが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが弱すぎます。6文字以上で設定してください';
      case 'invalid-email':
        return '無効なメールアドレスです';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく時間をおいてから再試行してください';
      case 'operation-not-allowed':
        return 'この認証方法は有効化されていません';
      case 'invalid-credential':
        return '認証情報が無効です';
      default:
        return '認証エラーが発生しました: ${e.message}';
    }
  }
}
