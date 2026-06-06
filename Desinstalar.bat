@echo off
:: Monitor de Uso  --  Desinstalar.bat

net session >nul 2>&1
if %errorlevel%==0 goto :ADMIN
powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ADMIN
cd /d "%~dp0"
title Monitor de Uso - Desinstalando...

echo.
echo  Monitor de Uso - Desinstalador
echo  ================================
echo.

schtasks /delete /tn "Monitor de Uso - Ativacao"   /f >nul 2>&1 && echo [OK] Removida: Ativacao   || echo [--] Nao encontrada: Ativacao
schtasks /delete /tn "Monitor de Uso - Inativacao" /f >nul 2>&1 && echo [OK] Removida: Inativacao || echo [--] Nao encontrada: Inativacao

echo.
echo  Pronto. Arquivos de relatorio mantidos em relatorios\
echo.
pause
