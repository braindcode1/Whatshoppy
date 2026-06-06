# WhatShoppy

Flutter app with a Node/Express backend and local AI product analysis.

## Local AI Flow

`AddProductScreen` calls `AiService.analyzeProductImage`, which posts the image to:

```text
POST /api/ai/analyze-image
```

The Node backend tries the local FastAPI service first:

- EfficientNet classifier from `whatshoppy_model_export`
- BLIP captioning with `Salesforce/blip-image-captioning-base`
- confidence threshold: `0.65`

If the local service fails, times out, or returns confidence below `0.65`, Node falls back to the existing Gemini flow. If Gemini is not configured, the route returns the existing demo-style response so the Flutter field filling still works.

## Run Instructions (Automated Setup)

We have created an automated startup system to handle the Python virtual environment, dependencies, and launching the services simultaneously. 

### Starting the Backend Services
To run both the Node.js backend and the FastAPI ML service with a single command, open your terminal at the root of the project and run:

```powershell
.\start-dev.ps1
```
Alternatively, just double-click the `start-dev.bat` file in Windows.

**What this script does:**
1. Checks for a Python virtual environment and creates one if missing.
2. Installs required Python and Node.js dependencies.
3. Starts the FastAPI ML service (`127.0.0.1:8000`).
4. Starts the Node.js backend (`0.0.0.0:3000`).
5. Implements graceful shutdown (closing the script window stops both services).

### Flutter Client & Networking

**Local dev** (same PC: USB `adb reverse`, emulator, or same Wi‑Fi): run without extra flags; the app tries `127.0.0.1:3000` and `10.0.2.2:3000` in debug mode.

**Any Wi‑Fi or mobile data**: deploy the backend to a server with **HTTPS**, then:

```powershell
flutter run --dart-define=API_BASE_URL=https://your-public-api.example.com
flutter build apk --dart-define=API_BASE_URL=https://your-public-api.example.com
```

Or set the URL in the app under **Settings → Backend server**.

See [docs/DEPLOY_ANYWHERE.md](docs/DEPLOY_ANYWHERE.md) for full deployment steps.

Optional backend environment variables:

```text
LOCAL_AI_URL=http://127.0.0.1:8000/analyze-image
LOCAL_AI_TIMEOUT_MS=20000
LOCAL_AI_CONFIDENCE_THRESHOLD=0.65
GEMINI_API_KEY=your_gemini_key
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

Run Flutter as usual:

```powershell
flutter pub get
flutter run
```
