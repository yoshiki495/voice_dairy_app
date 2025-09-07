"""
Firebase Functions for Voice Emotion Analysis
音声感情分析のためのFirebase Functions実装
"""

import os
import tempfile
from datetime import datetime
from typing import Dict, Any

from firebase_admin import initialize_app, firestore, storage
from firebase_functions import https_fn

# Firebase初期化
initialize_app()

# グローバル変数でモデルを保持（コールドスタート対策）
_classifier_pipeline = None
_regressor_pipeline = None
_label_encoder = None
_smile = None
_models_loaded = False


def _load_models():
    """機械学習モデルとopenSMILEを初期化（遅延ロード）"""
    global _classifier_pipeline, _regressor_pipeline, _label_encoder, _smile, _models_loaded
    
    if _models_loaded:
        return
    
    try:
        print("Loading emotion analysis models...")
        
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
            raise FileNotFoundError("Required model files are missing in functions/models/ directory")
        
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
        print("Models loaded successfully")
        
    except Exception as e:
        print(f"Error loading models: {e}")
        raise


def _extract_date_from_path(storage_path: str) -> str:
    """ストレージパスから日付を抽出"""
    return os.path.basename(storage_path).split('.')[0]


def _normalize_score(intensity: float) -> float:
    """感情強度を-1〜1の範囲に正規化"""
    return max(-1.0, min(1.0, float(intensity)))


@https_fn.on_call(region='asia-northeast1')
def test_function(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    テスト用の簡単な関数
    """
    return {
        'message': 'Firebase Functions is working!',
        'timestamp': datetime.now().isoformat(),
        'user_authenticated': req.auth is not None
    }


@https_fn.on_call(
    region='asia-northeast1',
    memory=512,
    timeout_sec=60
)
def get_upload_url(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    音声ファイルアップロード用の署名付きURL発行
    """
    # 認証チェック
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message='User must be authenticated'
        )
    
    try:
        data = req.data
        date = data.get('date')
        content_type = data.get('contentType', 'audio/m4a')
        
        if not date:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='Date is required'
            )
        
        # ストレージパスを生成
        user_id = req.auth.uid
        storage_path = f"audio/{user_id}/{date}.m4a"
        
        # Firebase Storageのバケットを取得
        bucket = storage.bucket()
        blob = bucket.blob(storage_path)
        
        # 署名付きURL生成（15分有効）
        upload_url = blob.generate_signed_url(
            version="v4",
            expiration=datetime.now().timestamp() + 15 * 60,  # 15分後
            method="PUT",
            content_type=content_type
        )
        
        return {
            'uploadUrl': upload_url,
            'storagePath': storage_path
        }
        
    except Exception as e:
        print(f"Error generating upload URL: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f'Failed to generate upload URL: {str(e)}'
        )


@https_fn.on_call(
    region='asia-northeast1',
    memory=1024,
    timeout_sec=300
)
def analyze_emotion(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    音声ファイルから感情分析を実行
    """
    # 認証チェック
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message='User must be authenticated'
        )
    
    try:
        # モデルを初期化
        _load_models()
        
        data = req.data
        storage_path = data.get('storagePath')
        recorded_at = data.get('recordedAt')
        
        if not storage_path:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='Storage path is required'
            )
        
        print(f"Analyzing emotion for: {storage_path}")
        
        # Firebase Storageから音声ファイルをダウンロード
        bucket = storage.bucket()
        blob = bucket.blob(storage_path)
        
        if not blob.exists():
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.NOT_FOUND,
                message='Audio file not found in storage'
            )
        
        # 一時ファイルに保存
        with tempfile.NamedTemporaryFile(suffix='.m4a', delete=False) as temp_file:
            try:
                blob.download_to_filename(temp_file.name)
                print(f"Downloaded audio file to: {temp_file.name}")
                
                # openSMILEで特徴量抽出
                features = _smile.process_file(temp_file.name)
                print(f"Extracted features shape: {features.shape}")
                
                # 特徴量の整形（必要に応じて欠損カラムを0で補完）
                # 注意: 実際の運用では学習時の特徴量カラムリストを保存しておく必要があります
                
                # 感情カテゴリ予測
                emotion_category_num = _classifier_pipeline.predict(features)[0]
                emotion_category = _label_encoder.inverse_transform([emotion_category_num])[0]
                
                # 感情強度予測
                emotion_intensity = _regressor_pipeline.predict(features)[0]
                
                # スコア正規化
                normalized_score = _normalize_score(emotion_intensity)
                
                print(f"Prediction results - Category: {emotion_category}, Intensity: {emotion_intensity}, Score: {normalized_score}")
                
            finally:
                # 一時ファイル削除
                if os.path.exists(temp_file.name):
                    os.unlink(temp_file.name)
        
        # Firestoreに結果保存
        db = firestore.client()
        date_key = _extract_date_from_path(storage_path)
        user_id = req.auth.uid
        
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
        print(f"Saved mood data to Firestore for user: {user_id}, date: {date_key}")
        
        return {
            'score': normalized_score,
            'category': emotion_category,
            'intensity': float(emotion_intensity),
            'timestamp': datetime.now().isoformat()
        }
        
    except https_fn.HttpsError:
        # HttpsErrorはそのまま再発生
        raise
    except Exception as e:
        print(f"Error in emotion analysis: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f'Emotion analysis failed: {str(e)}'
        )


@https_fn.on_call(
    region='asia-northeast1',
    memory=512,
    timeout_sec=60
)
def get_mood_data(req: https_fn.CallableRequest) -> Dict[str, Any]:
    """
    ユーザーの感情データを取得（週次グラフ用）
    """
    # 認証チェック
    if not req.auth:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message='User must be authenticated'
        )
    
    try:
        data = req.data
        start_date = data.get('startDate')  # YYYY-MM-DD format
        end_date = data.get('endDate')      # YYYY-MM-DD format
        
        if not start_date or not end_date:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message='Start date and end date are required'
            )
        
        # Firestoreからデータ取得
        db = firestore.client()
        user_id = req.auth.uid
        
        print(f"Project ID: {db.project}")
        print(f"User ID: {user_id}")
        print(f"Start date: {start_date}, End date: {end_date}")
        print("Testing database connection...")
        
        # データベース接続テスト
        try:
            db.collection('test').limit(1).get()
            print("Database connection successful")
        except Exception as db_error:
            print(f"Database connection failed: {db_error}")
            raise
        
        moods_ref = db.collection('users').document(user_id).collection('moods')
        query = moods_ref.where('date', '>=', start_date).where('date', '<=', end_date)
        
        mood_data = []
        for doc in query.stream():
            doc_data = doc.to_dict()
            mood_data.append({
                'date': doc.id,
                'score': doc_data.get('score'),
                'category': doc_data.get('category'),
                'intensity': doc_data.get('intensity'),
                'recordedAt': doc_data.get('recordedAt').isoformat() if doc_data.get('recordedAt') else None
            })
        
        return {
            'moods': mood_data,
            'count': len(mood_data)
        }
        
    except https_fn.HttpsError:
        raise
    except Exception as e:
        print(f"Error getting mood data: {str(e)}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=f'Failed to get mood data: {str(e)}'
        )
