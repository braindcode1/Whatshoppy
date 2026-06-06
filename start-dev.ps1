$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Starting WhatShoppy Backend Environment" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$baseDir = $PSScriptRoot
$aiDir = Join-Path $baseDir "backend\ai_model"
$ragDir = Join-Path $baseDir "backend\rag"
$nodeDir = Join-Path $baseDir "backend"

# --- 1. Python Environment ---
Write-Host "`n[1/4] Checking Python Environments..." -ForegroundColor Yellow

# AI Model Environment
$venvDir = Join-Path $aiDir ".venv"
if (-Not (Test-Path $venvDir)) {
    Write-Host "AI virtual environment not found. Creating one..." -ForegroundColor Gray
    Set-Location $aiDir
    python -m venv .venv
}
$pythonExe = Join-Path $venvDir "Scripts\python.exe"
$pipExe = Join-Path $venvDir "Scripts\pip.exe"
Write-Host "Installing AI requirements (if needed)..." -ForegroundColor Gray
Set-Location $aiDir
& $pipExe install -r requirements.txt | Out-Null
& $pipExe install opencv-python-headless | Out-Null # Ensure OpenCV is installed

# RAG Environment
$ragVenvDir = Join-Path $ragDir ".venv"
if (-Not (Test-Path $ragVenvDir)) {
    Write-Host "RAG virtual environment not found. Creating one..." -ForegroundColor Gray
    Set-Location $ragDir
    python -m venv .venv
}
$ragPythonExe = Join-Path $ragVenvDir "Scripts\python.exe"
$ragPipExe = Join-Path $ragVenvDir "Scripts\pip.exe"
Write-Host "Installing RAG requirements (if needed)..." -ForegroundColor Gray
Set-Location $ragDir
& $ragPipExe install -r requirements.txt | Out-Null

# --- 2. Node Environment ---
Write-Host "`n[2/4] Checking Node Environment..." -ForegroundColor Yellow
Set-Location $nodeDir
if (-Not (Test-Path (Join-Path $nodeDir "node_modules"))) {
    Write-Host "Installing Node modules..." -ForegroundColor Gray
    npm install
}

# --- 3. Start Services ---
Write-Host "`n[3/4] Starting Services..." -ForegroundColor Yellow

# Start FastAPI ML Service
Set-Location $aiDir
Write-Host "Starting FastAPI ML Service on http://127.0.0.1:8000..." -ForegroundColor Green
$pythonProcess = Start-Process -FilePath $pythonExe -ArgumentList "-m", "uvicorn", "yolo_service:app", "--host", "127.0.0.1", "--port", "8000", "--reload" -PassThru -NoNewWindow

# Start FastAPI RAG Service
Set-Location $ragDir
Write-Host "Starting FastAPI RAG Service on http://127.0.0.1:9000..." -ForegroundColor Green
$ragProcess = Start-Process -FilePath $ragPythonExe -ArgumentList "-m", "uvicorn", "rag_service:app", "--host", "127.0.0.1", "--port", "9000", "--reload" -PassThru -NoNewWindow

# Wait 2 seconds to ensure FastAPI services are up before Node starts making requests
Start-Sleep -Seconds 2

# Start Node.js Backend
Set-Location $nodeDir
Write-Host "Starting Node.js Backend on port 3000..." -ForegroundColor Green
$nodeProcess = Start-Process -FilePath "node" -ArgumentList "server.js" -PassThru -NoNewWindow

# --- 4. Wait & Graceful Shutdown ---
Write-Host "`n[4/4] Environment is running! Press Ctrl+C to stop.`n" -ForegroundColor Cyan
Write-Host "The Flutter app will automatically discover the Node.js backend on the network." -ForegroundColor Green

try {
    while ($true) {
        Start-Sleep -Seconds 1
        if ($pythonProcess.HasExited) {
            Write-Host "FastAPI ML service stopped unexpectedly." -ForegroundColor Red
            break
        }
        if ($ragProcess.HasExited) {
            Write-Host "FastAPI RAG service stopped unexpectedly." -ForegroundColor Red
            break
        }
        if ($nodeProcess.HasExited) {
            Write-Host "Node.js Backend stopped unexpectedly." -ForegroundColor Red
            break
        }
    }
} finally {
    Write-Host "`nShutting down services gracefully..." -ForegroundColor Yellow
    if (-not $pythonProcess.HasExited) { 
        Stop-Process -Id $pythonProcess.Id -Force -ErrorAction SilentlyContinue 
    }
    if ($ragProcess -and -not $ragProcess.HasExited) { 
        Stop-Process -Id $ragProcess.Id -Force -ErrorAction SilentlyContinue 
    }
    if (-not $nodeProcess.HasExited) { 
        Stop-Process -Id $nodeProcess.Id -Force -ErrorAction SilentlyContinue 
    }
    Write-Host "Shutdown complete." -ForegroundColor Green
}
