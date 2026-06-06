# Use WhatShoppy from any Wi‑Fi or mobile data

Your phone cannot reach `127.0.0.1` or `192.168.x.x` on your PC when you are on another network or mobile data. The backend must run on a **public server** with **HTTPS**, and the Flutter app must call that URL.

## Architecture

```text
Phone (any network)
    → https://your-api.example.com  (Node.js on cloud)
        → http://127.0.0.1:9000   (RAG FastAPI, same server)
        → http://127.0.0.1:8000   (AI FastAPI, same server)
        → Supabase (already cloud)
```

Supabase already works globally. You only need to deploy **Node + RAG + AI** (or disable AI features until deployed).

## Step 1 — Deploy the backend (one VPS or PaaS)

### Option A: VPS (Hetzner, DigitalOcean, AWS EC2, etc.)

On the server:

1. Install Node 20+, Python 3.11+.
2. Clone the project, copy `backend/.env` from `.env.example` and fill Supabase + Gemini keys.
3. Build RAG index once:
   ```bash
   cd backend/rag
   python -m venv .venv
   source .venv/bin/activate   # Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   python build_index.py
   ```
4. Run services with **process manager** (systemd, PM2, or supervisor):
   - RAG: `uvicorn rag_service:app --host 127.0.0.1 --port 9000`
   - AI: your existing FastAPI on port 8000
   - Node: `node server.js` with `PORT=3000`
5. Put **Nginx** or **Caddy** in front with HTTPS (Let’s Encrypt) proxying to `localhost:3000`.

### Option B: Render / Railway / Fly.io

- Deploy **Node** as the web service (public URL).
- Deploy **RAG** as a second private service, or run RAG on the same machine.
- Set environment variables on the Node service:
  - `RAG_SERVICE_URL=http://rag-service:9000` (internal URL on the platform)
  - `LOCAL_AI_BASE_URL=http://ai-service:8000`
  - `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`

Use **HTTPS** URLs only for the Flutter app.

## Step 2 — Point Flutter to the public URL

Build or run with your public API base (no trailing slash):

```powershell
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

Release APK:

```powershell
flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com
```

The app checks that URL first. In **release** mode it does not fall back to `127.0.0.1`.

### Optional: change server without rebuilding

Open **Settings → Backend server** in the app, enter your HTTPS URL, tap **Save & test**.

## Step 3 — Verify

```bash
curl https://your-api.example.com/health
```

From the phone browser (on mobile data), open the same URL. If it loads, Flutter will work too.

## Quick test (not for production)

**ngrok** can expose your local Node temporarily:

```powershell
ngrok http 3000
```

Use the `https://xxxx.ngrok-free.app` URL as `API_BASE_URL`. Free tunnels change URL on restart and are rate-limited.

## Checklist

| Item | Required for “anywhere” |
|------|-------------------------|
| Public HTTPS API URL | Yes |
| Flutter `API_BASE_URL` or Settings override | Yes |
| RAG + index on server | Yes (for navigation chatbot) |
| AI service on server | Only for image analysis features |
| Same Wi‑Fi / USB / `127.0.0.1` | No — local dev only |
