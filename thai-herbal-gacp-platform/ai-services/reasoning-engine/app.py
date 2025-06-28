import os
import logging
import json
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
import numpy as np
from PIL import Image
import io
import torch
from torchvision import transforms
import pandas as pd
from sklearn.base import BaseEstimator
import joblib

# Initialize logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("gacp-ai-reasoning")

# Initialize FastAPI app
app = FastAPI(
    title="GACP AI Reasoning Engine",
    description="AI services for Thai Herbal GACP Platform",
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
class Config:
    MODEL_DIR = os.getenv("MODEL_DIR", "/app/models")
    KNOWLEDGE_BASE_PATH = os.getenv("KNOWLEDGE_BASE_PATH", "/app/knowledge/gacp_rules.json")
    DOCUMENT_TYPES = {
        "commercial_registration": "ทะเบียนพาณิชย์",
        "land_document": "เอกสารสิทธิ์ในที่ดิน",
        "farm_map": "แผนผังฟาร์ม",
        "soil_test_report": "รายงานผลตรวจดิน",
    }
    HERBAL_TYPES = {
        "andrographis": "ฟ้าทะลายโจร",
        "curcuma": "กระชาย",
        "ginger": "ขิง",
        "turmeric": "ขมิ้น",
        "lemongrass": "ตะไคร้",
    }

# Load models and knowledge base
try:
    # Load document classification model
    document_model = torch.jit.load(os.path.join(Config.MODEL_DIR, "document_classifier.pt"))
    document_model.eval()
    
    # Load predictive model
    predictive_model: BaseEstimator = joblib.load(
        os.path.join(Config.MODEL_DIR, "yield_predictor.pkl")
    )
    
    # Load knowledge base
    with open(Config.KNOWLEDGE_BASE_PATH, "r", encoding="utf-8") as f:
        knowledge_base = json.load(f)
    
    logger.info("AI models and knowledge base loaded successfully")
except Exception as e:
    logger.error(f"Failed to load models: {str(e)}")
    raise RuntimeError("Model loading failed") from e

# Transformation for document images
document_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])

# Pydantic models
class DocumentValidationRequest:
    document_type: str
    content: bytes

class DocumentValidationResult(BaseModel):
    document_type: str
    is_valid: bool
    confidence: float
    issues: List[str]
    thai_name: str

class DocumentValidationResponse(BaseModel):
    overall_valid: bool
    results: List[DocumentValidationResult]

class HerbalType(BaseModel):
    name: str
    thai_name: str

class PredictionRequest(BaseModel):
    features: Dict[str, float]
    herbal_types: List[HerbalType]

class PredictionResult(BaseModel):
    prediction: float
    confidence: float
    recommendations: List[str]

class KnowledgeGraphQuery(BaseModel):
    entities: List[str]
    relationships: List[str]

class KnowledgeGraphResponse(BaseModel):
    results: List[Dict]

# Document validation endpoint
@app.post("/validate-documents", response_model=DocumentValidationResponse)
async def validate_documents(files: List[UploadFile] = File(...)):
    """
    Validate multiple documents for GACP compliance
    
    - **files**: List of document files to validate
    """
    results = []
    overall_valid = True
    
    for file in files:
        try:
            # Read file content
            content = await file.read()
            
            # Get document type from filename
            document_type = os.path.splitext(file.filename)[0]
            thai_name = Config.DOCUMENT_TYPES.get(document_type, "เอกสารไม่ระบุประเภท")
            
            # Validate document
            if document_type in ["commercial_registration", "land_document"]:
                # PDF validation logic
                is_valid, confidence, issues = validate_pdf(content, document_type)
            else:
                # Image validation logic
                is_valid, confidence, issues = validate_image(content, document_type)
            
            if not is_valid:
                overall_valid = False
                
            results.append(DocumentValidationResult(
                document_type=document_type,
                is_valid=is_valid,
                confidence=confidence,
                issues=issues,
                thai_name=thai_name
            ))
            
        except Exception as e:
            logger.error(f"Error validating document {file.filename}: {str(e)}")
            results.append(DocumentValidationResult(
                document_type=document_type,
                is_valid=False,
                confidence=0.0,
                issues=[f"Validation error: {str(e)}"],
                thai_name="เอกสารไม่ระบุประเภท"
            ))
            overall_valid = False
            
    return DocumentValidationResponse(
        overall_valid=overall_valid,
        results=results
    )

def validate_pdf(content: bytes, doc_type: str) -> (bool, float, List[str]):
    """Validate PDF documents using OCR and rule-based checks"""
    # In production, we'd use OCR libraries like Tesseract
    # For demo, we'll simulate validation
    
    # Check if document is valid PDF
    if content[:4] != b'%PDF':
        return False, 0.0, ["รูปแบบไฟล์ไม่ถูกต้อง ควรเป็น PDF"]
    
    # Simulate content validation
    content_str = content[:1000].decode('latin-1', errors='ignore').lower()
    
    issues = []
    if doc_type == "commercial_registration":
        if "company" not in content_str and "registration" not in content_str:
            issues.append("ไม่พบข้อมูลทะเบียนพาณิชย์")
        
        # Check expiration date logic would go here
        
    elif doc_type == "land_document":
        if "land" not in content_str and "title" not in content_str:
            issues.append("ไม่พบข้อมูลเอกสารสิทธิ์ในที่ดิน")
    
    is_valid = len(issues) == 0
    confidence = 0.95 if is_valid else 0.45
    
    return is_valid, confidence, issues

def validate_image(content: bytes, doc_type: str) -> (bool, float, List[str]):
    """Validate image documents using computer vision"""
    try:
        # Load and preprocess image
        img = Image.open(io.BytesIO(content))
        
        if img.mode != 'RGB':
            img = img.convert('RGB')
            
        img_tensor = document_transform(img).unsqueeze(0)
        
        # Predict with model
        with torch.no_grad():
            output = document_model(img_tensor)
            _, pred = torch.max(output, 1)
            confidence = torch.nn.functional.softmax(output, dim=1)[0][pred].item()
        
        # Check if prediction matches document type
        predicted_class = pred.item()
        target_class = list(Config.DOCUMENT_TYPES.keys()).index(doc_type)
        is_valid = predicted_class == target_class
        
        issues = []
        if not is_valid:
            predicted_name = list(Config.DOCUMENT_TYPES.values())[predicted_class]
            issues.append(f"ประเภทเอกสารไม่ตรงกัน: คาดว่าเป็น {predicted_name}")
        
        # Additional rule-based checks
        if doc_type == "farm_map":
            # Check for map elements
            if not contains_map_elements(img):
                issues.append("ไม่พบองค์ประกอบแผนที่ที่สำคัญ")
                confidence *= 0.7
        
        return is_valid, confidence, issues
        
    except Exception as e:
        logger.error(f"Image validation error: {str(e)}")
        return False, 0.0, [f"Image processing error: {str(e)}"]

def contains_map_elements(img: Image.Image) -> bool:
    """Check for basic map elements (simulated)"""
    # In production, we'd use CV techniques
    return np.random.random() > 0.2  # 80% chance of passing

# Predictive analytics endpoint
@app.post("/predict", response_model=PredictionResult)
async def predict_yield(request: PredictionRequest):
    """
    Predict herbal yield based on environmental factors
    
    - **features**: Dictionary of environmental features
    - **herbal_types**: List of herbal types to predict
    """
    try:
        # Prepare features
        feature_df = pd.DataFrame([request.features])
        
        # Add herbal type features
        for herb in request.herbal_types:
            feature_df[f"herb_{herb.name}"] = 1
        
        # Predict
        prediction = predictive_model.predict(feature_df)[0]
        
        # Generate recommendations
        recommendations = generate_recommendations(request.features, request.herbal_types)
        
        return PredictionResult(
            prediction=prediction,
            confidence=0.85,  # Confidence would come from model in production
            recommendations=recommendations
        )
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

def generate_recommendations(features: Dict, herbs: List[HerbalType]) -> List[str]:
    """Generate cultivation recommendations based on features and herbs"""
    recs = []
    
    # Soil moisture recommendations
    moisture = features.get("soil_moisture", 0.5)
    if moisture < 0.3:
        recs.append("ควรเพิ่มการรดน้ำ ดินมีความชื้นต่ำเกินไป")
    elif moisture > 0.7:
        recs.append("ควรลดการรดน้ำ ดินมีความชื้นสูงเกินไป")
    
    # Temperature recommendations
    temp = features.get("temperature", 25)
    if temp < 20:
        recs.append("อุณหภูมิต่ำเกินไปสำหรับสมุนไพรบางชนิด ควรพิจารณาใช้โรงเรือน")
    
    # Herb-specific recommendations
    for herb in herbs:
        herb_recs = knowledge_base.get("herbs", {}).get(herb.name, {}).get("recommendations", [])
        recs.extend(herb_recs)
    
    return recs[:5]  # Return top 5 recommendations

# Knowledge graph endpoint
@app.post("/query-knowledge", response_model=KnowledgeGraphResponse)
async def query_knowledge_graph(query: KnowledgeGraphQuery):
    """
    Query the GACP knowledge graph
    
    - **entities**: Entities to query
    - **relationships**: Relationships to explore
    """
    try:
        results = []
        
        # In production, this would query a real knowledge graph
        # For demo, we'll simulate results from our knowledge base
        
        for entity in query.entities:
            entity_data = knowledge_base.get("entities", {}).get(entity, {})
            if entity_data:
                result = {"entity": entity, "data": entity_data}
                
                # Add relationships
                for rel in query.relationships:
                    if rel in entity_data.get("relationships", {}):
                        result[rel] = entity_data["relationships"][rel]
                
                results.append(result)
        
        return KnowledgeGraphResponse(results=results)
        
    except Exception as e:
        logger.error(f"Knowledge query error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Health check endpoint
@app.get("/health")
def health_check():
    return {"status": "healthy", "model_loaded": True}

# Main entry point
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=int(os.getenv("PORT", "5000")),
        log_level="info"
    )
