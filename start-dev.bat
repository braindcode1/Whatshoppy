@echo off
title WhatShoppy Backend Server
echo Starting WhatShoppy Backend Setup...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0start-dev.ps1"
pause
