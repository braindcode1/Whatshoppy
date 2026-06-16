@echo off
setlocal EnableExtensions EnableDelayedExpansion

title WhatShoppy Full Project Launcher

set "ROOT=%~dp0"
set "BACKEND_DIR=%ROOT%backend"
set "AI_DIR=%ROOT%backend\ai_model"
set "RAG_DIR=%ROOT%backend\rag"
set "API_PORT=3000"
set "AI_PORT=8000"
set "RAG_PORT=9000"
set "APP_PACKAGE=com.example.whatshoppy2"
set "APP_ACTIVITY=com.example.whatshoppy2/.MainActivity"
set "APK_PATH=%ROOT%build\app\outputs\flutter-apk\app-debug.apk"

set "NODE_EXE=node"
if exist "C:\Program Files\nodejs\node.exe" set "NODE_EXE=C:\Program Files\nodejs\node.exe"

set "ADB_EXE=%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe"
if not exist "%ADB_EXE%" set "ADB_EXE=adb"

set "AI_PY=%AI_DIR%\.venv\Scripts\python.exe"
set "RAG_PY=%RAG_DIR%\.venv\Scripts\python.exe"

echo =========================================
echo WhatShoppy full project launcher
echo =========================================
echo API backend : http://127.0.0.1:%API_PORT%
echo AI model    : http://127.0.0.1:%AI_PORT%
echo RAG service : http://127.0.0.1:%RAG_PORT%
echo.

if not exist "%BACKEND_DIR%\server.js" (
  echo [ERROR] Backend server.js not found: "%BACKEND_DIR%\server.js"
  goto :fail
)

if not exist "%AI_PY%" (
  echo [ERROR] AI virtualenv Python not found: "%AI_PY%"
  echo Run the setup once or create it with:
  echo   cd backend\ai_model
  echo   python -m venv .venv
  echo   .venv\Scripts\pip install -r requirements.txt
  goto :fail
)

if not exist "%RAG_PY%" (
  echo [ERROR] RAG virtualenv Python not found: "%RAG_PY%"
  echo Run the setup once or create it with:
  echo   cd backend\rag
  echo   python -m venv .venv
  echo   .venv\Scripts\pip install -r requirements.txt
  goto :fail
)

call :start_if_needed %AI_PORT% "WhatShoppy AI 8000" "%AI_DIR%" "%AI_PY%" "-m uvicorn yolo_service:app --host 127.0.0.1 --port %AI_PORT%" "ai_model.stdout.log" "ai_model.stderr.log"
call :start_if_needed %RAG_PORT% "WhatShoppy RAG 9000" "%RAG_DIR%" "%RAG_PY%" "-m uvicorn rag_service:app --host 127.0.0.1 --port %RAG_PORT%" "rag.stdout.log" "rag.stderr.log"
call :start_if_needed %API_PORT% "WhatShoppy API 3000" "%BACKEND_DIR%" "%NODE_EXE%" "server.js" "backend.stdout.log" "backend.stderr.log"

echo.
echo Waiting for services to answer...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$targets=@('http://127.0.0.1:%AI_PORT%/health','http://127.0.0.1:%RAG_PORT%/health','http://127.0.0.1:%API_PORT%/health');" ^
  "foreach($u in $targets){" ^
  "  $ok=$false;" ^
  "  for($i=0;$i -lt 40;$i++){" ^
  "    try{ $r=Invoke-RestMethod -Uri $u -TimeoutSec 2; if($r.success -eq $true){$ok=$true; break} }catch{};" ^
  "    Start-Sleep -Seconds 2" ^
  "  };" ^
  "  if($ok){ Write-Host ('[OK] ' + $u) } else { Write-Host ('[WARN] Not ready: ' + $u) }" ^
  "}"

echo.
echo Looking for connected Android phone...
set "DEVICE_ID="
"%ADB_EXE%" devices > "%TEMP%\adb_devices.txt" 2>nul
for /f "tokens=1" %%D in ('findstr /R /C:"device$" "%TEMP%\adb_devices.txt"') do (
  if not defined DEVICE_ID set "DEVICE_ID=%%D"
)
del "%TEMP%\adb_devices.txt" 2>nul

if not defined DEVICE_ID (
  echo [WARN] No Android device found. Backend/API/AI/RAG are running, but app was not launched.
  echo Connect your phone with USB debugging, then run this file again.
  goto :done
)

echo [OK] Android device: %DEVICE_ID%

echo Creating ADB reverse tunnels...
"%ADB_EXE%" -s "%DEVICE_ID%" reverse tcp:%API_PORT% tcp:%API_PORT% >nul 2>nul
"%ADB_EXE%" -s "%DEVICE_ID%" reverse tcp:%AI_PORT% tcp:%AI_PORT% >nul 2>nul
"%ADB_EXE%" -s "%DEVICE_ID%" reverse tcp:%RAG_PORT% tcp:%RAG_PORT% >nul 2>nul
"%ADB_EXE%" -s "%DEVICE_ID%" reverse --list

echo.
echo Checking installed Flutter app...
"%ADB_EXE%" -s "%DEVICE_ID%" shell pm list packages %APP_PACKAGE% | findstr /C:"package:%APP_PACKAGE%" >nul
if errorlevel 1 (
  if exist "%APK_PATH%" (
    echo App is not installed. Installing existing debug APK...
    "%ADB_EXE%" -s "%DEVICE_ID%" install -r "%APK_PATH%"
  ) else (
    echo [WARN] App is not installed and APK was not found:
    echo   "%APK_PATH%"
    echo Build it once with:
    echo   flutter build apk --debug
    goto :done
  )
)

echo Launching Flutter app...
"%ADB_EXE%" -s "%DEVICE_ID%" shell am start -n %APP_ACTIVITY%

echo.
echo =========================================
echo Full project is running.
echo API  : http://127.0.0.1:%API_PORT%
echo AI   : http://127.0.0.1:%AI_PORT%
echo RAG  : http://127.0.0.1:%RAG_PORT%
echo App  : %APP_PACKAGE% on %DEVICE_ID%
echo =========================================
echo.
echo Close the service windows or stop their processes when finished.
goto :done

:start_if_needed
set "PORT=%~1"
set "TITLE_TEXT=%~2"
set "WORK_DIR=%~3"
set "EXE_PATH=%~4"
set "ARGS=%~5"
set "OUT_LOG=%~6"
set "ERR_LOG=%~7"

powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-NetTCPConnection -LocalPort %PORT% -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if not errorlevel 1 (
  echo [OK] Port %PORT% already running: %TITLE_TEXT%
  exit /b 0
)

echo [START] %TITLE_TEXT%
start "%TITLE_TEXT%" /min cmd /c "cd /d "%WORK_DIR%" && "%EXE_PATH%" %ARGS% >> "%OUT_LOG%" 2>> "%ERR_LOG%""
exit /b 0

:fail
echo.
echo Failed to start full project.
exit /b 1

:done
echo.
pause
endlocal
