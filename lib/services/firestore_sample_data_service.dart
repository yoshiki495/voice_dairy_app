import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirestoreSampleDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Random _random = Random();

  /// 今日から10日前から10日分のサンプルデータをFirestoreに追加
  Future<void> addSampleData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final now = DateTime.now();
    final batch = _firestore.batch();

    // 10日前から10日分のデータを作成
    for (int i = 9; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      
      // ランダムなスコアを生成（-1.0 から 1.0）
      // より自然な分布にする
      double score;
      final rand = _random.nextDouble();
      if (rand < 0.3) {
        // 30%の確率でポジティブ（0.2〜1.0）
        score = 0.2 + (_random.nextDouble() * 0.8);
      } else if (rand < 0.6) {
        // 30%の確率でニュートラル（-0.2〜0.2）
        score = (_random.nextDouble() * 0.4) - 0.2;
      } else {
        // 40%の確率でネガティブ（-1.0〜-0.2）
        score = -1.0 + (_random.nextDouble() * 0.8);
      }
      
      final normalizedScore = double.parse(score.toStringAsFixed(2));
      
      // カテゴリを決定
      String category;
      if (normalizedScore >= 0.1) {
        category = 'positive';
      } else if (normalizedScore <= -0.1) {
        category = 'negative';
      } else {
        category = 'neutral';
      }
      
      // Firestoreのドキュメント参照
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .doc(dateString);
      
      // データを作成
      final moodData = {
        'score': normalizedScore,
        'category': category,
        'intensity': normalizedScore.abs(),
        'recordedAt': Timestamp.fromDate(DateTime(
          date.year,
          date.month,
          date.day,
          20, // 20:00 JST
          _random.nextInt(60), // ランダムな分
        )),
        'storagePath': 'audio/${user.uid}/$dateString.m4a',
        'source': 'sample_data',
        'version': 3,
      };
      
      batch.set(docRef, moodData);
    }

    // バッチ実行
    await batch.commit();
  }

  /// 既存のサンプルデータを削除
  Future<void> clearSampleData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .where('source', isEqualTo: 'sample_data')
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// すべてのmoodデータを削除
  Future<void> clearAllMoodData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

