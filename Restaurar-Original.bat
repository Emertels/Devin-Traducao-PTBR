@echo off
title Restaurador PT-BR - Devin AI - Emerson Teles
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0core\restaurar.ps1"
exit /b %ERRORLEVEL%
