"""
Flask API for Voice Emotion Analysis on Cloud Run
音声感情分析のためのCloud Run Flask API実装
"""

import os
import tempfile
import logging
from datetime import datetime
from typing import Dict, Any, Optional

import numpy as np
import pandas as pd
from flask import Flask, request, jsonify
from google.cloud import firestore, storage
from google.oauth2 import service_account
import firebase_admin
from firebase_admin import auth, credentials

# Firebase初期化
if not firebase_admin._apps:
    cred = credentials.ApplicationDefault()
    firebase_admin.initialize_app(cred)

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# グローバル変数でモデルを保持（コールドスタート対策）
_classifier_pipeline = None
_regressor_pipeline = None
_label_encoder = None
_smile = None
_models_loaded = False

# 環境変数
PROJECT_ID = os.getenv('GOOGLE_CLOUD_PROJECT', 'voice-dairy-app-70a9d')
FIRESTORE_DATABASE = os.getenv('FIRESTORE_DATABASE', 'default')


def _load_models():
    """機械学習モデルとopenSMILEを初期化（遅延ロード）"""
    global _classifier_pipeline, _regressor_pipeline, _label_encoder, _smile, _models_loaded
    
    if _models_loaded:
        return
    
    try:
        logger.info("Loading emotion analysis models...")
        
        # 機械学習ライブラリを関数内でインポート
        import joblib
        import opensmile
        
        # モデルファイルのパス
        models_dir = os.path.join(os.path.dirname(__file__), 'models')
        
        # モデルファイルの存在確認
        classifier_path = os.path.join(models_dir, 'best_emotion_classifier_pipeline.pkl')
        regressor_path = os.path.join(models_dir, 'best_emotion_regressor_pipeline.pkl')
        encoder_path = os.path.join(models_dir, 'label_encoder.pkl')
        
        if not all(os.path.exists(path) for path in [classifier_path, regressor_path, encoder_path]):
            raise FileNotFoundError("Required model files are missing in models/ directory")
        
        # モデルをロード
        _classifier_pipeline = joblib.load(classifier_path)
        _regressor_pipeline = joblib.load(regressor_path)
        _label_encoder = joblib.load(encoder_path)
        
        # openSMILE初期化
        _smile = opensmile.Smile(
            feature_set=opensmile.FeatureSet.ComParE_2016,
            feature_level=opensmile.FeatureLevel.Functionals
        )
        
        _models_loaded = True
        logger.info("Models loaded successfully")
        
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        raise


def _verify_token(token: str) -> Optional[Dict[str, Any]]:
    """Firebase ID トークンを検証"""
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        return None


def _extract_date_from_path(storage_path: str) -> str:
    """ストレージパスから日付を抽出"""
    return os.path.basename(storage_path).split('.')[0]


def _normalize_score(intensity: float) -> float:
    """感情強度を-1〜1の範囲に正規化"""
    return max(-1.0, min(1.0, float(intensity)))


@app.route('/health', methods=['GET'])
def health_check():
    """ヘルスチェックエンドポイント"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'voice-emotion-analysis'
    })


@app.route('/test', methods=['POST'])
def test_function():
    """テスト用エンドポイント"""
    auth_header = request.headers.get('Authorization')
    user_info = None
    
    if auth_header and auth_header.startswith('Bearer '):
        token = auth_header.split(' ')[1]
        user_info = _verify_token(token)
    
    return jsonify({
        'message': 'Cloud Run Flask API is working!',
        'timestamp': datetime.now().isoformat(),
        'user_authenticated': user_info is not None,
        'user_id': user_info.get('uid') if user_info else None
    })


@app.route('/get-upload-url', methods=['POST'])
def get_upload_url():
    """音声ファイルアップロード用の署名付きURL発行"""
    # 認証チェック
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Authentication required'}), 401
    
    token = auth_header.split(' ')[1]
    user_info = _verify_token(token)
    if not user_info:
        return jsonify({'error': 'Invalid token'}), 401
    
    try:
        data = request.get_json()
        date = data.get('date')
        content_type = data.get('contentType', 'audio/m4a')
        
        if not date:
            return jsonify({'error': 'Date is required'}), 400
        
        # ストレージパスを生成
        user_id = user_info['uid']
        storage_path = f"audio/{user_id}/{date}.m4a"
        
        # Google Cloud Storageクライアント初期化
        storage_client = storage.Client(project=PROJECT_ID)
        bucket = storage_client.bucket(f"{PROJECT_ID}.appspot.com")
        blob = bucket.blob(storage_path)
        
        # 署名付きURL生成（15分有効）
        upload_url = blob.generate_signed_url(
            version="v4",
            expiration=datetime.now().timestamp() + 15 * 60,  # 15分後
            method="PUT",
            content_type=content_type
        )
        
        return jsonify({
            'uploadUrl': upload_url,
            'storagePath': storage_path
        })
        
    except Exception as e:
        logger.error(f"Error generating upload URL: {str(e)}")
        return jsonify({'error': f'Failed to generate upload URL: {str(e)}'}), 500


@app.route('/analyze-emotion', methods=['POST'])
def analyze_emotion():
    """音声ファイルから感情分析を実行"""
    # 認証チェック
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Authentication required'}), 401
    
    token = auth_header.split(' ')[1]
    user_info = _verify_token(token)
    if not user_info:
        return jsonify({'error': 'Invalid token'}), 401
    
    try:
        # モデルを初期化
        _load_models()
        
        data = request.get_json()
        storage_path = data.get('storagePath')
        recorded_at = data.get('recordedAt')
        
        if not storage_path:
            return jsonify({'error': 'Storage path is required'}), 400
        
        logger.info(f"Analyzing emotion for: {storage_path}")
        
        # Google Cloud Storageから音声ファイルをダウンロード
        storage_client = storage.Client(project=PROJECT_ID)
        bucket = storage_client.bucket(f"{PROJECT_ID}.appspot.com")
        blob = bucket.blob(storage_path)
        
        if not blob.exists():
            return jsonify({'error': 'Audio file not found in storage'}), 404
        
        # 一時ファイルに保存
        with tempfile.NamedTemporaryFile(suffix='.m4a', delete=False) as temp_file:
            try:
                blob.download_to_filename(temp_file.name)
                logger.info(f"Downloaded audio file to: {temp_file.name}")
                
                # openSMILEで特徴量抽出
                features = _smile.process_file(temp_file.name)
                logger.info(f"Extracted features shape: {features.shape}")
                
                # 特徴量の整形（必要に応じて欠損カラムを0で補完）
                # 注意: 実際の運用では学習時の特徴量カラムリストを保存しておく必要があります
                
                # 感情カテゴリ予測
                emotion_category_num = _classifier_pipeline.predict(features)[0]
                emotion_category = _label_encoder.inverse_transform([emotion_category_num])[0]
                
                # 感情強度予測
                emotion_intensity = _regressor_pipeline.predict(features)[0]
                
                # スコア正規化
                normalized_score = _normalize_score(emotion_intensity)
                
                logger.info(f"Prediction results - Category: {emotion_category}, Intensity: {emotion_intensity}, Score: {normalized_score}")
                
            finally:
                # 一時ファイル削除
                if os.path.exists(temp_file.name):
                    os.unlink(temp_file.name)
        
        # Firestoreに結果保存
        db = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE)
        date_key = _extract_date_from_path(storage_path)
        user_id = user_info['uid']
        
        mood_data = {
            'score': normalized_score,
            'category': emotion_category,
            'intensity': float(emotion_intensity),
            'recordedAt': firestore.SERVER_TIMESTAMP,
            'storagePath': storage_path,
            'source': 'daily_20_jst',
            'version': 2  # 機械学習モデル版
        }
        
        db.collection('users').document(user_id).collection('moods').document(date_key).set(mood_data)
        logger.info(f"Saved mood data to Firestore for user: {user_id}, date: {date_key}")
        
        return jsonify({
            'score': normalized_score,
            'category': emotion_category,
            'intensity': float(emotion_intensity),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in emotion analysis: {str(e)}")
        return jsonify({'error': f'Emotion analysis failed: {str(e)}'}), 500


@app.route('/get-mood-data', methods=['POST'])
def get_mood_data():
    """ユーザーの感情データを取得（週次グラフ用）"""
    # 認証チェック
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({'error': 'Authentication required'}), 401
    
    token = auth_header.split(' ')[1]
    user_info = _verify_token(token)
    if not user_info:
        return jsonify({'error': 'Invalid token'}), 401
    
    try:
        data = request.get_json()
        start_date = data.get('startDate')  # YYYY-MM-DD format
        end_date = data.get('endDate')      # YYYY-MM-DD format
        
        if not start_date or not end_date:
            return jsonify({'error': 'Start date and end date are required'}), 400
        
        # Firestoreからデータ取得
        db = firestore.Client(project=PROJECT_ID, database=FIRESTORE_DATABASE)
        user_id = user_info['uid']
        
        logger.info(f"Project ID: {PROJECT_ID}")
        logger.info(f"User ID: {user_id}")
        logger.info(f"Start date: {start_date}, End date: {end_date}")
        
        moods_ref = db.collection('users').document(user_id).collection('moods')
        # 日付範囲でのクエリは難しいため、すべて取得してフィルタリング
        query = moods_ref.stream()
        
        mood_data = []
        for doc in query:
            doc_data = doc.to_dict()
            date_id = doc.id
            # 日付フィルタリング
            if start_date <= date_id <= end_date:
                mood_data.append({
                    'date': date_id,
                    'score': doc_data.get('score'),
                    'category': doc_data.get('category'),
                    'intensity': doc_data.get('intensity'),
                    'recordedAt': doc_data.get('recordedAt').isoformat() if doc_data.get('recordedAt') else None
                })
        
        return jsonify({
            'moods': mood_data,
            'count': len(mood_data)
        })
        
    except Exception as e:
        logger.error(f"Error getting mood data: {str(e)}")
        return jsonify({'error': f'Failed to get mood data: {str(e)}'}), 500


if __name__ == '__main__':
    # 開発用サーバー
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)