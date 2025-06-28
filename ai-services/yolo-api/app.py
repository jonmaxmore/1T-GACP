#!/usr/bin/env python3
# ===================================================================
# Error Handlers
# ===================================================================

@app.errorhandler(400)
def bad_request(error):
    return jsonify({
        'success': False,
        'error': 'Bad Request',
        'message': str(error.description),
        'timestamp': datetime.now().isoformat()
    }), 400

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'success': False,
        'error': 'Not Found',
        'message': 'The requested resource was not found',
        'timestamp': datetime.now().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({
        'success': False,
        'error': 'Internal Server Error',
        'message': 'An unexpected error occurred',
        'timestamp': datetime.now().isoformat()
    }), 500

@app.errorhandler(Exception)
def handle_exception(e):
    logger.error(f"Unhandled exception: {str(e)}\n{traceback.format_exc()}")
    return jsonify({
        'success': False,
        'error': 'Unexpected Error',
        'message': 'An unexpected error occurred during processing',
        'timestamp': datetime.now().isoformat()
    }), 500

# ===================================================================
# Application Initialization
# ===================================================================

def create_app():
    """Application factory pattern"""
    
    # Ensure required directories exist
    os.makedirs('logs', exist_ok=True)
    os.makedirs('uploads', exist_ok=True)
    os.makedirs('models', exist_ok=True)
    os.makedirs('temp', exist_ok=True)
    
    # Initialize models
    try:
        logger.info("🤖 Loading AI models...")
        model_manager.load_models()
        logger.info("✅ AI models loaded successfully")
    except Exception as e:
        logger.error(f"❌ Failed to load models: {str(e)}")
        # Continue with demo mode
        logger.warning("⚠️ Running in demo mode without real models")
    
    # Initialize image processor
    try:
        image_processor.initialize()
        logger.info("✅ Image processor initialized")
    except Exception as e:
        logger.error(f"❌ Image processor initialization failed: {str(e)}")
    
    return app

# ===================================================================
# Main Execution
# ===================================================================

if __name__ == '__main__':
    # Create application
    app = create_app()
    
    # Development server
    if app.config.get('DEBUG', False):
        logger.info("🔧 Running in development mode")
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=True,
            threaded=True
        )
    else:
        # Production server
        logger.info("🚀 Running in production mode")
        from waitress import serve
        serve(
            app,
            host='0.0.0.0',
            port=5000,
            threads=4,
            max_request_body_size=50 * 1024 * 1024  # 50MB max
        )

# ===================================================================
# Additional Utility Functions
# ===================================================================

def validate_image_format(image_data: bytes) -> bool:
    """Validate image format and integrity"""
    try:
        image = Image.open(io.BytesIO(image_data))
        image.verify()
        return True
    except Exception:
        return False

def get_image_metadata(image_data: bytes) -> Dict[str, Any]:
    """Extract image metadata"""
    try:
        image = Image.open(io.BytesIO(image_data))
        return {
            'format': image.format,
            'mode': image.mode,
            'size': image.size,
            'has_transparency': image.mode in ('RGBA', 'LA'),
            'dpi': image.info.get('dpi', (72, 72))
        }
    except Exception as e:
        logger.error(f"Failed to extract image metadata: {str(e)}")
        return {}

def optimize_image_for_processing(image: np.ndarray) -> np.ndarray:
    """Optimize image for AI processing"""
    # Convert to RGB if needed
    if len(image.shape) == 3 and image.shape[2] == 4:  # RGBA
        image = cv2.cvtColor(image, cv2.COLOR_RGBA2RGB)
    elif len(image.shape) == 3 and image.shape[2] == 1:  # Grayscale
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    
    # Resize if too large
    max_size = 1024
    height, width = image.shape[:2]
    if max(height, width) > max_size:
        scale = max_size / max(height, width)
        new_width = int(width * scale)
        new_height = int(height * scale)
        image = cv2.resize(image, (new_width, new_height), interpolation=cv2.INTER_AREA)
    
    return image

# ===================================================================
# Performance Monitoring
# ===================================================================

import time
from functools import wraps

def monitor_performance(func):
    """Decorator to monitor function performance"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        try:
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            logger.info(f"Function {func.__name__} executed in {execution_time:.3f}s")
            return result
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"Function {func.__name__} failed after {execution_time:.3f}s: {str(e)}")
            raise
    return wrapper

# ===================================================================
# Configuration Validation
# ===================================================================

def validate_configuration():
    """Validate application configuration"""
    required_configs = [
        'SECRET_KEY',
        'MODEL_PATH',
        'UPLOAD_FOLDER',
        'MAX_CONTENT_LENGTH'
    ]
    
    missing_configs = []
    for config in required_configs:
        if not app.config.get(config):
            missing_configs.append(config)
    
    if missing_configs:
        raise ValueError(f"Missing required configurations: {', '.join(missing_configs)}")
    
    # Validate model files exist
    model_path = Path(app.config['MODEL_PATH'])
    if not model_path.exists():
        logger.warning(f"Model directory does not exist: {model_path}")
        os.makedirs(model_path, exist_ok=True)

# ===================================================================
# Startup Checks
# ===================================================================

def run_startup_checks():
    """Run comprehensive startup checks"""
    logger.info("🔍 Running startup checks...")
    
    # Check Python version
    import sys
    if sys.version_info < (3, 8):
        raise RuntimeError("Python 3.8+ is required")
    
    # Check CUDA availability
    if torch.cuda.is_available():
        logger.info(f"✅ CUDA available - GPU: {torch.cuda.get_device_name()}")
    else:
        logger.info("⚠️ CUDA not available - running on CPU")
    
    # Check disk space
    import shutil
    total, used, free = shutil.disk_usage('/')
    free_gb = free // (1024**3)
    if free_gb < 5:  # Less than 5GB free
        logger.warning(f"⚠️ Low disk space: {free_gb}GB free")
    
    # Check memory
    import psutil
    memory = psutil.virtual_memory()
    if memory.available < 2 * (1024**3):  # Less than 2GB available
        logger.warning(f"⚠️ Low memory: {memory.available // (1024**3)}GB available")
    
    # Validate configuration
    try:
        validate_configuration()
        logger.info("✅ Configuration validated")
    except Exception as e:
        logger.error(f"❌ Configuration validation failed: {str(e)}")
        raise
    
    logger.info("✅ All startup checks passed")

# ===================================================================
# Application Entry Point
# ===================================================================

def main():
    """Main application entry point"""
    try:
        # Run startup checks
        run_startup_checks()
        
        # Create and configure application
        app = create_app()
        
        # Start server based on environment
        if os.getenv('FLASK_ENV') == 'development':
            logger.info("🔧 Starting development server...")
            app.run(
                host='0.0.0.0',
                port=int(os.getenv('PORT', 5000)),
                debug=True,
                threaded=True
            )
        else:
            logger.info("🚀 Starting production server...")
            from waitress import serve
            serve(
                app,
                host='0.0.0.0',
                port=int(os.getenv('PORT', 5000)),
                threads=8,
                connection_limit=1000,
                max_request_body_size=50 * 1024 * 1024,  # 50MB
                cleanup_interval=30,
                channel_timeout=300
            )
            
    except KeyboardInterrupt:
        logger.info("👋 Server shutdown requested by user")
    except Exception as e:
        logger.error(f"❌ Failed to start server: {str(e)}")
        raise

if __name__ == '__main__':
    main()

# ===================================================================
# Production Deployment Notes
# ===================================================================

"""
Production Deployment Checklist:

1. Environment Variables:
   - Set FLASK_ENV=production
   - Configure SECRET_KEY
   - Set appropriate PORT
   - Configure model paths

2. Model Files:
   - Download pre-trained models to /models directory
   - Verify model file integrity
   - Set appropriate file permissions

3. Dependencies:
   - Install production requirements
   - Use specific version pins
   - Consider using virtual environment

4. Security:
   - Enable HTTPS in production
   - Configure CORS properly
   - Set up rate limiting
   - Enable request logging

5. Monitoring:
   - Set up health check endpoints
   - Configure logging to external service
   - Monitor memory and CPU usage
   - Set up alerts for errors

6. Performance:
   - Use production WSGI server (Gunicorn/uWSGI)
   - Configure worker processes
   - Enable response compression
   - Set up load balancing if needed

7. Docker Deployment:
   - Use multi-stage Docker build
   - Optimize image size
   - Configure resource limits
   - Set up health checks

Example Docker command:
docker run -d \
  -p 5000:5000 \
  -v /host/models:/app/models \
  -v /host/logs:/app/logs \
  -e FLASK_ENV=production \
  -e SECRET_KEY=your-secret-key \
  thai-herbal-yolo-api:latest

Example Kubernetes deployment:
kubectl apply -f k8s/yolo-api-deployment.yaml
kubectl apply -f k8s/yolo-api-service.yaml
kubectl apply -f k8s/yolo-api-ingress.yaml
"""
# Thai Herbal GACP Platform v3.0 - YOLO AI Service
# ===================================================================

import os
import io
import json
import logging
import traceback
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any
from pathlib import Path

import cv2
import numpy as np
import torch
from PIL import Image
import albumentations as A
from ultralytics import YOLO

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from flask_restx import Api, Resource, fields
from werkzeug.utils import secure_filename
from werkzeug.exceptions import BadRequest, InternalServerError

# Custom modules
from utils.image_processor import ImageProcessor
from utils.model_manager import ModelManager
from utils.thai_herb_classifier import ThaiHerbClassifier
from utils.quality_assessor import QualityAssessor
from utils.digital_signature import DigitalSigner
from utils.response_formatter import ResponseFormatter
from config.settings import Settings
from models.herb_models import HerbPrediction, QualityAssessment, DetectionResult

# ===================================================================
# Application Setup
# ===================================================================

# Initialize Flask app
app = Flask(__name__)
app.config.from_object(Settings)

# Setup CORS
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:8080", "https://thaiherbalgacp.com"],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# Setup API documentation
api = Api(
    app,
    version='3.0',
    title='Thai Herbal GACP AI API',
    description='Computer Vision API for Thai Herbal Quality Assessment',
    doc='/docs/',
    prefix='/api/v1'
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/yolo_api.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ===================================================================
# Global Services
# ===================================================================

# Initialize services
model_manager = ModelManager()
image_processor = ImageProcessor()
herb_classifier = ThaiHerbClassifier()
quality_assessor = QualityAssessor()
digital_signer = DigitalSigner()
response_formatter = ResponseFormatter()

# ===================================================================
# API Models (for documentation)
# ===================================================================

# Request models
image_upload_model = api.model('ImageUpload', {
    'image': fields.Raw(required=True, description='Base64 encoded image or file upload'),
    'herb_type': fields.String(description='Expected herb type (optional)'),
    'assessment_type': fields.String(description='Type of assessment', enum=['classification', 'quality', 'disease'])
})

# Response models
herb_prediction_model = api.model('HerbPrediction', {
    'herb_type': fields.String(description='Predicted herb type'),
    'confidence': fields.Float(description='Prediction confidence (0-1)'),
    'subspecies': fields.String(description='Subspecies if applicable'),
    'botanical_name': fields.String(description='Scientific name')
})

quality_assessment_model = api.model('QualityAssessment', {
    'overall_score': fields.Float(description='Overall quality score (0-1)'),
    'freshness': fields.Float(description='Freshness score'),
    'color': fields.Float(description='Color quality score'),
    'texture': fields.Float(description='Texture quality score'),
    'size': fields.Float(description='Size consistency score'),
    'defects': fields.List(fields.String, description='List of detected defects'),
    'grade': fields.String(description='Quality grade (A, B, C, D)'),
    'gacp_compliance': fields.Float(description='GACP compliance score')
})

detection_result_model = api.model('DetectionResult', {
    'objects': fields.List(fields.Nested(api.model('DetectedObject', {
        'class_name': fields.String(description='Object class'),
        'confidence': fields.Float(description='Detection confidence'),
        'bbox': fields.List(fields.Float, description='Bounding box [x, y, w, h]'),
        'area': fields.Float(description='Object area in pixels')
    }))),
    'total_objects': fields.Integer(description='Total number of detected objects'),
    'processing_time': fields.Float(description='Processing time in seconds')
})

analysis_response_model = api.model('AnalysisResponse', {
    'success': fields.Boolean(description='Analysis success status'),
    'analysis_id': fields.String(description='Unique analysis ID'),
    'timestamp': fields.String(description='Analysis timestamp'),
    'herb_prediction': fields.Nested(herb_prediction_model),
    'quality_assessment': fields.Nested(quality_assessment_model),
    'detection_result': fields.Nested(detection_result_model),
    'recommendations': fields.List(fields.String, description='Quality improvement recommendations'),
    'digital_signature': fields.String(description='Digital signature for integrity'),
    'metadata': fields.Raw(description='Additional metadata')
})

# ===================================================================
# API Endpoints
# ===================================================================

@api.route('/health')
class HealthCheck(Resource):
    def get(self):
        """Health check endpoint"""
        try:
            # Check model availability
            model_status = model_manager.check_models()
            gpu_available = torch.cuda.is_available()
            
            return {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'models': model_status,
                'gpu_available': gpu_available,
                'version': '3.0.0'
            }
        except Exception as e:
            logger.error(f"Health check failed: {str(e)}")
            return {'status': 'unhealthy', 'error': str(e)}, 500

@api.route('/models')
class ModelInfo(Resource):
    def get(self):
        """Get information about available models"""
        try:
            models_info = model_manager.get_models_info()
            return {
                'available_models': models_info,
                'supported_herbs': [
                    'cannabis', 'turmeric', 'ginger', 
                    'black_galingale', 'plai', 'kratom'
                ],
                'supported_formats': ['jpg', 'jpeg', 'png', 'bmp', 'tiff']
            }
        except Exception as e:
            logger.error(f"Model info error: {str(e)}")
            return {'error': str(e)}, 500

@api.route('/analyze')
class HerbAnalysis(Resource):
    @api.expect(image_upload_model)
    @api.marshal_with(analysis_response_model)
    def post(self):
        """Comprehensive herb analysis including classification and quality assessment"""
        try:
            analysis_id = f"analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{os.urandom(4).hex()}"
            logger.info(f"Starting analysis: {analysis_id}")
            
            # Validate request
            if 'image' not in request.files and 'image' not in request.json:
                raise BadRequest("No image provided")
            
            # Process image
            image = self._extract_image_from_request()
            processed_image = image_processor.preprocess_image(image)
            
            # Get analysis parameters
            herb_type = request.form.get('herb_type') or request.json.get('herb_type')
            assessment_type = request.form.get('assessment_type', 'comprehensive')
            
            # Perform comprehensive analysis
            start_time = datetime.now()
            
            # 1. Herb Classification
            herb_prediction = herb_classifier.classify_herb(processed_image)
            
            # 2. Quality Assessment
            quality_assessment = quality_assessor.assess_quality(
                processed_image, 
                herb_prediction.herb_type
            )
            
            # 3. Object Detection
            detection_result = self._detect_objects(processed_image)
            
            # 4. Disease/Pest Detection (if applicable)
            disease_detection = self._detect_diseases(processed_image, herb_prediction.herb_type)
            
            # 5. Generate recommendations
            recommendations = self._generate_recommendations(
                herb_prediction, quality_assessment, disease_detection
            )
            
            processing_time = (datetime.now() - start_time).total_seconds()
            
            # Create response data
            response_data = {
                'success': True,
                'analysis_id': analysis_id,
                'timestamp': datetime.now().isoformat(),
                'herb_prediction': herb_prediction.to_dict(),
                'quality_assessment': quality_assessment.to_dict(),
                'detection_result': detection_result.to_dict(),
                'recommendations': recommendations,
                'metadata': {
                    'processing_time': processing_time,
                    'model_versions': model_manager.get_model_versions(),
                    'image_properties': image_processor.get_image_properties(processed_image)
                }
            }
            
            # Add digital signature for integrity
            response_data['digital_signature'] = digital_signer.sign_response(response_data)
            
            # Log successful analysis
            logger.info(f"Analysis completed: {analysis_id} in {processing_time:.2f}s")
            
            return response_data
            
        except BadRequest as e:
            logger.warning(f"Bad request: {str(e)}")
            return {'success': False, 'error': str(e)}, 400
        except Exception as e:
            logger.error(f"Analysis failed: {str(e)}\n{traceback.format_exc()}")
            return {'success': False, 'error': 'Internal analysis error'}, 500

    def _extract_image_from_request(self) -> np.ndarray:
        """Extract and validate image from request"""
        if 'image' in request.files:
            # File upload
            file = request.files['image']
            if file.filename == '':
                raise BadRequest("No file selected")
            
            # Validate file type
            if not self._allowed_file(file.filename):
                raise BadRequest("Invalid file type")
            
            # Read image
            image_bytes = file.read()
            image = Image.open(io.BytesIO(image_bytes))
            return np.array(image)
            
        elif request.is_json and 'image' in request.json:
            # Base64 encoded image
            import base64
            image_data = request.json['image']
            if image_data.startswith('data:image'):
                # Remove data URL prefix
                image_data = image_data.split(',')[1]
            
            image_bytes = base64.b64decode(image_data)
            image = Image.open(io.BytesIO(image_bytes))
            return np.array(image)
        else:
            raise BadRequest("No valid image provided")

    def _allowed_file(self, filename: str) -> bool:
        """Check if file type is allowed"""
        allowed_extensions = {'png', 'jpg', 'jpeg', 'bmp', 'tiff', 'webp'}
        return '.' in filename and \
               filename.rsplit('.', 1)[1].lower() in allowed_extensions

    def _detect_objects(self, image: np.ndarray) -> DetectionResult:
        """Detect objects in the image"""
        try:
            # Load YOLO model
            model = model_manager.get_model('object_detection')
            
            # Run detection
            results = model(image)
            
            # Process results
            objects = []
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for box in boxes:
                        objects.append({
                            'class_name': model.names[int(box.cls)],
                            'confidence': float(box.conf),
                            'bbox': box.xyxy.tolist()[0],
                            'area': float(box.area) if hasattr(box, 'area') else 0
                        })
            
            return DetectionResult(
                objects=objects,
                total_objects=len(objects),
                processing_time=0  # Will be calculated by caller
            )
            
        except Exception as e:
            logger.error(f"Object detection failed: {str(e)}")
            return DetectionResult(objects=[], total_objects=0, processing_time=0)

    def _detect_diseases(self, image: np.ndarray, herb_type: str) -> List[str]:
        """Detect diseases and pests"""
        try:
            # Load disease detection model for specific herb
            model = model_manager.get_disease_model(herb_type)
            if model is None:
                return []
            
            # Run disease detection
            results = model.predict(image)
            
            # Process results
            diseases = []
            for result in results:
                if result['confidence'] > 0.5:  # Threshold for disease detection
                    diseases.append(result['disease_name'])
            
            return diseases
            
        except Exception as e:
            logger.error(f"Disease detection failed: {str(e)}")
            return []

    def _generate_recommendations(self, 
                                herb_prediction: HerbPrediction,
                                quality_assessment: QualityAssessment,
                                diseases: List[str]) -> List[str]:
        """Generate quality improvement recommendations"""
        recommendations = []
        
        # Quality-based recommendations
        if quality_assessment.overall_score < 0.7:
            recommendations.append("คุณภาพโดยรวมต่ำกว่ามาตรฐาน ควรปรับปรุงกระบวนการผลิต")
        
        if quality_assessment.freshness < 0.6:
            recommendations.append("ความสดใหม่ไม่เพียงพอ ควรปรับปรุงการเก็บรักษา")
        
        if quality_assessment.color < 0.6:
            recommendations.append("สีไม่ตรงตามมาตรฐาน ตรวจสอบกระบวนการอบแห้ง")
        
        if quality_assessment.defects:
            recommendations.append(f"พบข้อบกพร่อง: {', '.join(quality_assessment.defects)}")
        
        # Disease-based recommendations
        if diseases:
            recommendations.append(f"พบโรคพืช: {', '.join(diseases)} ควรรักษาและป้องกัน")
        
        # Herb-specific recommendations
        herb_specific = self._get_herb_specific_recommendations(
            herb_prediction.herb_type, quality_assessment
        )
        recommendations.extend(herb_specific)
        
        # GACP compliance recommendations
        if quality_assessment.gacp_compliance < 0.8:
            recommendations.append("ควรปรับปรุงให้เป็นไปตามมาตรฐาน GACP")
        
        return recommendations

    def _get_herb_specific_recommendations(self, 
                                         herb_type: str, 
                                         quality: QualityAssessment) -> List[str]:
        """Get herb-specific recommendations"""
        recommendations = []
        
        if herb_type == 'cannabis':
            if quality.texture < 0.7:
                recommendations.append("ดอกกัญชาควรมีความแน่นเหมาะสม")
            if quality.color < 0.7:
                recommendations.append("สีเขียวควรสม่ำเสมอ ไม่เหลืองหรือน้ำตาล")
                
        elif herb_type == 'turmeric':
            if quality.color < 0.7:
                recommendations.append("สีเหลืองของขมิ้นควรสด ไม่จืด")
            if quality.size < 0.7:
                recommendations.append("ขนาดหัวขมิ้นควรสม่ำเสมอ")
                
        elif herb_type == 'ginger':
            if quality.texture < 0.7:
                recommendations.append("เนื้อขิงควรแกร่ง ไม่อ่อนนิ่ม")
            if quality.freshness < 0.7:
                recommendations.append("ขิงควรสด ไม่เหี่ยวแห้ง")
        
        return recommendations

@api.route('/classify')
class HerbClassification(Resource):
    def post(self):
        """Classify herb type only"""
        try:
            image = self._extract_image_from_request()
            processed_image = image_processor.preprocess_image(image)
            
            # Classify herb
            prediction = herb_classifier.classify_herb(processed_image)
            
            return {
                'success': True,
                'timestamp': datetime.now().isoformat(),
                'prediction': prediction.to_dict()
            }
            
        except Exception as e:
            logger.error(f"Classification failed: {str(e)}")
            return {'success': False, 'error': str(e)}, 500

    def _extract_image_from_request(self):
        # Same as in HerbAnalysis class
        if 'image' in request.files:
            file = request.files['image']
            image_bytes = file.read()
            image = Image.open(io.BytesIO(image_bytes))
            return np.array(image)
        else:
            raise BadRequest("No image provided")

@api.route('/quality')
class QualityAssessmentEndpoint(Resource):
    def post(self):
        """Assess herb quality only"""
        try:
            image = self._extract_image_from_request()
            herb_type = request.form.get('herb_type', 'unknown')
            
            processed_image = image_processor.preprocess_image(image)
            
            # Assess quality
            assessment = quality_assessor.assess_quality(processed_image, herb_type)
            
            return {
                'success': True,
                'timestamp': datetime.now().isoformat(),
                'assessment': assessment.to_dict()
            }
            
        except Exception as e:
            logger.error(f"Quality assessment failed: {str(e)}")
            return {'success': False, 'error': str(e)}, 500

    def _extract_image_from_request(self):
        # Same implementation as above
        if 'image' in request.files:
            file = request.files['image']
            image_bytes = file.read()
            image = Image.open(io.BytesIO(image_bytes))
            return np.array(image)
        else:
            raise BadRequest("No image provided")

# ===================================================================
# Batch Processing Endpoints
# ===================================================================

@api.route('/batch/analyze')
class BatchAnalysis(Resource):
    def post(self):
        """Batch analysis for multiple images"""
        try:
            if 'images' not in request.files:
                raise BadRequest("No images provided")
            
            files = request.files.getlist('images')
            if len(files) > 10:  # Limit batch size
                raise BadRequest("Maximum 10 images per batch")
            
            results = []
            for i, file in enumerate(files):
                try:
                    image_bytes = file.read()
                    image = Image.open(io.BytesIO(image_bytes))
                    processed_image = image_processor.preprocess_image(np.array(image))
                    
                    # Quick analysis
                    herb_prediction = herb_classifier.classify_herb(processed_image)
                    quality_assessment = quality_assessor.assess_quality(
                        processed_image, herb_prediction.herb_type
                    )
                    
                    results.append({
                        'index': i,
                        'filename': file.filename,
                        'herb_prediction': herb_prediction.to_dict(),
                        'quality_assessment': quality_assessment.to_dict(),
                        'success': True
                    })
                    
                except Exception as e:
                    results.append({
                        'index': i,
                        'filename': file.filename,
                        'error': str(e),
                        'success': False
                    })
            
            return {
                'success': True,
                'timestamp': datetime.now().isoformat(),
                'total_images': len(files),
                'successful_analyses': len([r for r in results if r['success']]),
                'results': results
            }
            
        except Exception as e:
            logger.error(f"Batch analysis failed: {str(e)}")
            return {'success': False, 'error': str(e)}, 500

# ===================================================================
# Model Management Endpoints
# ===================================================================

@api.route('/models/reload')
class ModelReload(Resource):
    def post(self):
        """Reload AI models"""
        try:
            model_manager.reload_models()
            return {
                'success': True,
                'message': 'Models reloaded successfully',
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            logger.error(f"Model reload failed: {str(e)}")
            return {'success': False, 'error': str(e)}, 500

# ===================================================================
# Static Files
# ===================================================================

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    """Serve uploaded files"""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# ===================================================================
