import base64
import io
import json
import pickle
import logging
from pathlib import Path
from typing import Any

import joblib
import numpy as np
import tensorflow as tf
from fastapi import FastAPI, HTTPException, Request, UploadFile
from PIL import Image
from pydantic import BaseModel

# ============================================================
# Paths
# ============================================================

SERVICE_DIR = Path(__file__).resolve().parent
WORKSPACE_DIR = SERVICE_DIR.parent.parent
KERAS_MODEL_PATH = WORKSPACE_DIR / "model result" / "best_clothes_model.keras"
CLASS_NAMES_PATH = WORKSPACE_DIR / "model result" / "class_names.json"
PRICE_MODEL_PATH = SERVICE_DIR / "fashion_price_predictor.pkl"

# ============================================================
# Logger
# ============================================================

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("WhatShoppyKerasService")

# ============================================================
# FastAPI app
# ============================================================

app = FastAPI(title="WhatShoppy Local Keras ML Service")

# ============================================================
# Global models
# ============================================================

keras_model = None
class_names = []
model_error = None
price_model = None

# Translations from Indonesian to English
ENGLISH_MAPPING = {
    "Blazer": "Blazer",
    "Celana_Panjang": "Pants",
    "Celana_Pendek": "Shorts",
    "Gaun": "Dress",
    "Hoodie": "Hoodie",
    "Jaket": "Jacket",
    "Jaket_Denim": "Denim Jacket",
    "Jaket_Olahraga": "Sports Jacket",
    "Jeans": "Jeans",
    "Kaos": "T-Shirt",
    "Kemeja": "Shirt",
    "Mantel": "Coat",
    "Polo": "Polo Shirt",
    "Rok": "Skirt",
    "Sweter": "Sweater"
}

# ============================================================
# Load Keras model
# ============================================================

try:
    if KERAS_MODEL_PATH.exists():
        keras_model = tf.keras.models.load_model(str(KERAS_MODEL_PATH))
        logger.info("Successfully loaded Keras clothes classification model.")
    else:
        model_error = f"Keras model file not found at {KERAS_MODEL_PATH}"
        logger.error(model_error)

    if CLASS_NAMES_PATH.exists():
        with open(CLASS_NAMES_PATH, "r", encoding="utf-8") as f:
            class_names = json.load(f)
        logger.info(f"Loaded class names successfully: {class_names}")
    else:
        logger.error(f"Class names JSON file not found at {CLASS_NAMES_PATH}")
except Exception as e:
    model_error = str(e)
    logger.error(f"Failed to load Keras model: {e}")

# ============================================================
# Price model utilities
# ============================================================

def _load_price_model() -> Any:
    global price_model

    if price_model is None:
        if not PRICE_MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Missing price prediction model file: {PRICE_MODEL_PATH}"
            )

        try:
            price_model = joblib.load(PRICE_MODEL_PATH)
        except Exception:
            with PRICE_MODEL_PATH.open("rb") as handle:
                price_model = pickle.load(handle)

    return price_model


def _extract_prediction_value(prediction: Any) -> float:
    array = np.asarray(prediction, dtype=float).reshape(-1)

    if array.size == 0:
        raise ValueError("Price model returned an empty prediction")

    value = float(array[0])

    if not np.isfinite(value):
        raise ValueError("Price model returned an invalid prediction")

    return value

# ============================================================
# Schemas
# ============================================================

PRICE_COLUMNS = [
    "Brand",
    "Category",
    "Color",
    "Size",
    "Material",
    "Gender",
    "Season",
    "Brand_Tier",
]


class PricePredictionRequest(BaseModel):
    Brand: str
    Category: str
    Color: str
    Size: str
    Material: str
    Gender: str
    Season: str
    Brand_Tier: str


class AnalyzeImageRequest(BaseModel):
    image_base64: str
    mime_type: str | None = None

# ============================================================
# Image utilities
# ============================================================

def _decode_image(image_base64: str) -> Image.Image:
    try:
        if not image_base64:
            raise ValueError("Empty base64 image")

        if "," in image_base64:
            image_base64 = image_base64.split(",", 1)[1]

        raw = base64.b64decode(image_base64)
        image = Image.open(io.BytesIO(raw)).convert("RGB")

        return image

    except Exception as exc:
        raise ValueError("image_base64 must be a valid base64-encoded image") from exc

# ============================================================
# Health endpoint
# ============================================================

@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "success": True,
        "source": "keras",
        "keras_loaded": keras_model is not None,
        "keras_error": model_error,
        "price_model_loaded": price_model is not None or PRICE_MODEL_PATH.exists(),
        "price_model_path": str(PRICE_MODEL_PATH),
        "price_model_exists": PRICE_MODEL_PATH.exists(),
    }

# ============================================================
# Model info endpoint
# ============================================================

@app.get("/model-info")
def model_info() -> dict[str, Any]:
    if keras_model is None:
        return {
            "success": False,
            "error": model_error,
            "model_path": str(KERAS_MODEL_PATH),
            "model_exists": KERAS_MODEL_PATH.exists(),
        }

    return {
        "success": True,
        "model_path": str(KERAS_MODEL_PATH),
        "model_exists": KERAS_MODEL_PATH.exists(),
        "classes": class_names,
    }

# ============================================================
# Analyze image endpoint
# ============================================================

@app.post("/analyze-image")
async def analyze_image(request: Request, conf: float = 0.15) -> dict[str, Any]:
    if keras_model is None:
        raise HTTPException(
            status_code=500,
            detail=f"Keras model is not loaded. Error: {model_error}",
        )

    content_type = request.headers.get("content-type", "")
    image = None

    try:
        if "application/json" in content_type or content_type == "":
            payload = await request.json()
            image_base64 = payload.get("image_base64")
            if not image_base64:
                raise HTTPException(status_code=400, detail="image_base64 is required")
            image = _decode_image(image_base64)
        elif "multipart/form-data" in content_type:
            form = await request.form()
            file = form.get("file")
            if not file or not isinstance(file, UploadFile):
                raise HTTPException(status_code=400, detail="file is required")
            contents = await file.read()
            image = Image.open(io.BytesIO(contents)).convert("RGB")
        else:
            raise HTTPException(status_code=415, detail="Unsupported Media Type")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image input: {str(e)}")

    # 2. Run Inference
    try:
        image_resized = image.resize((224, 224))
        img_arr = np.array(image_resized, dtype=np.float32)
        img_arr = np.expand_dims(img_arr, axis=0)
        preds = keras_model.predict(img_arr)[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference execution failed: {str(e)}")

    # 3. Process Detections
    class_idx = int(np.argmax(preds))
    confidence = float(preds[class_idx])
    raw_class_name = class_names[class_idx] if class_idx < len(class_names) else "General"
    class_name = ENGLISH_MAPPING.get(raw_class_name, raw_class_name)
    
    detections = []
    if confidence >= conf:
        width, height = image.size
        detections.append({
            "class": class_name,
            "confidence": round(confidence, 4),
            "box": [0.0, 0.0, float(width), float(height)]
        })
        main_category = class_name
        main_confidence = confidence
    else:
        main_category = "General"
        main_confidence = 0.0

    return {
        "success": True,
        "source": "keras",
        "data": {
            "name": "",
            "description": "",
            "category": main_category,
            "tags": [d["class"] for d in detections],
            "estimated_price": None,
            "confidence": round(main_confidence, 4),
            "model_category": main_category,
            "detections": detections
        }
    }

# ============================================================
# Compatibility predict endpoint
# ============================================================

@app.post("/predict")
async def predict(payload: AnalyzeImageRequest, conf: float = 0.15) -> dict[str, Any]:
    if keras_model is None:
        raise HTTPException(status_code=500, detail="Keras model is not loaded")
    try:
        image = _decode_image(payload.image_base64)
        
        # Preprocess
        image_resized = image.resize((224, 224))
        img_arr = np.array(image_resized, dtype=np.float32)
        img_arr = np.expand_dims(img_arr, axis=0)
        
        preds = keras_model.predict(img_arr)[0]
        class_idx = int(np.argmax(preds))
        confidence = float(preds[class_idx])
        
        if confidence >= conf:
            raw_class_name = class_names[class_idx] if class_idx < len(class_names) else "General"
            prediction = ENGLISH_MAPPING.get(raw_class_name, raw_class_name)
            return {"prediction": prediction}
        else:
            return {"prediction": "General"}
    except Exception as exc:
        if isinstance(exc, HTTPException):
            raise exc
        raise HTTPException(status_code=500, detail=str(exc)) from exc

# ============================================================
# Price prediction endpoint
# ============================================================

@app.post("/predict-price")
def predict_price(payload: PricePredictionRequest) -> dict[str, Any]:
    try:
        import pandas as pd

        model_price = _load_price_model()

        data = {column: [getattr(payload, column)] for column in PRICE_COLUMNS}

        data["Rating"] = [4.5]
        data["Reviews"] = [10]
        data["Discount"] = [0.0]

        final_columns = [
            "Brand",
            "Category",
            "Color",
            "Size",
            "Material",
            "Rating",
            "Reviews",
            "Discount",
            "Gender",
            "Season",
            "Brand_Tier",
        ]

        input_df = pd.DataFrame(data, columns=final_columns)

        prediction = model_price.predict(input_df)
        recommended_price = _extract_prediction_value(prediction)

        return {
            "success": True,
            "recommended_price": round(recommended_price, 2),
            "data": {
                "recommended_price": round(recommended_price, 2),
            },
        }

    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc