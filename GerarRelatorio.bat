@echo off
:: Monitor de Uso  --  GerarRelatorio.bat
:: Nao precisa de administrador.
cd /d "%~dp0"
powershell -NonInteractive -ExecutionPolicy Bypass -File "%~dp0scripts\GerarRelatorio.ps1" -ConfigPath "%~dp0config.ini"
