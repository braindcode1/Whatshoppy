# WhatShoppy Local ML Service

FastAPI service used by the Node backend when the Flutter app calls
`POST /api/ai/analyze-image`.

It loads the classic machine learning model files from this folder:

- `detection.pkl`: optional pipeline or transformer/scaler
- `clothes_svm_model.pkl`: SVM classifier
- `label_encoder.pkl`: category label decoder

The image preprocessing extracts HOG features from a grayscale image resized to
`64 x 64`, producing the 1764-feature vectors expected by the saved scaler/SVM
assets.

## Run

```powershell
cd backend\ai_model
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app:app --host 127.0.0.1 --port 8000
```

The Node backend calls `http://127.0.0.1:8000/analyze-image` by default.
