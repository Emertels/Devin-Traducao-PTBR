@echo off
title Instalador PT-BR - Devin AI - Emerson Teles
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\instalar.ps1"
set "PS_EXIT=%ERRORLEVEL%"
if not "%PS_EXIT%"=="0" (
    echo.
    echo O instalador do Devin terminou com erro. Leia a mensagem acima.
    pause
)
exit /b %PS_EXIT%
