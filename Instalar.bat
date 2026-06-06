@echo off
:: ============================================================
:: Monitor de Uso  --  Instalar.bat
:: Duplo clique para instalar. Solicita admin automaticamente.
:: ============================================================

:: Auto-elevacao sem abrir nova janela visivel
net session >nul 2>&1
if %errorlevel%==0 goto :ADMIN
powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ADMIN
cd /d "%~dp0"
title Monitor de Uso - Instalando...

echo.
echo  Monitor de Uso - Instalador
echo  ============================
echo.

:: Caminhos
set "SCRIPT=%~dp0scripts\RegistrarEvento.ps1"
set "CFG=%~dp0config.ini"

if not exist "%SCRIPT%" (
    echo [ERRO] Nao encontrado: %SCRIPT%
    pause & exit /b 1
)

:: Politica de execucao
powershell -WindowStyle Hidden -Command "Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force" >nul 2>&1
echo [OK] Politica de execucao configurada.

:: Remove tarefas anteriores
schtasks /delete /tn "Monitor de Uso - Ativacao"   /f >nul 2>&1
schtasks /delete /tn "Monitor de Uso - Inativacao" /f >nul 2>&1

:: ============================================================
:: Monta argumento PowerShell para rodar COMPLETAMENTE oculto
:: Usamos wscript.exe + vbs inline para nao abrir NENHUMA janela
:: ============================================================
set "ARG_ATIV=-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT%\" -Tipo ATIVACAO"
set "ARG_INATIV=-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT%\" -Tipo INATIVACAO"

:: ============================================================
:: Tarefa ATIVACAO  (disparador: SessionUnlock)
:: ============================================================
set "XML1=%TEMP%\mu_ativ.xml"
> "%XML1%" echo ^<?xml version="1.0" encoding="UTF-16"?^>
>>"%XML1%" echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
>>"%XML1%" echo   ^<Triggers^>
>>"%XML1%" echo     ^<SessionStateChangeTrigger^>
>>"%XML1%" echo       ^<Enabled^>true^</Enabled^>
>>"%XML1%" echo       ^<StateChange^>SessionUnlock^</StateChange^>
>>"%XML1%" echo     ^</SessionStateChangeTrigger^>
>>"%XML1%" echo   ^</Triggers^>
>>"%XML1%" echo   ^<Principals^>
>>"%XML1%" echo     ^<Principal id="Author"^>
>>"%XML1%" echo       ^<LogonType^>InteractiveToken^</LogonType^>
>>"%XML1%" echo       ^<RunLevel^>LeastPrivilege^</RunLevel^>
>>"%XML1%" echo     ^</Principal^>
>>"%XML1%" echo   ^</Principals^>
>>"%XML1%" echo   ^<Settings^>
>>"%XML1%" echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
>>"%XML1%" echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
>>"%XML1%" echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
>>"%XML1%" echo     ^<Hidden^>true^</Hidden^>
>>"%XML1%" echo     ^<ExecutionTimeLimit^>PT1M^</ExecutionTimeLimit^>
>>"%XML1%" echo   ^</Settings^>
>>"%XML1%" echo   ^<Actions Context="Author"^>
>>"%XML1%" echo     ^<Exec^>
>>"%XML1%" echo       ^<Command^>wscript.exe^</Command^>
>>"%XML1%" echo       ^<Arguments^>//nologo "%~dp0scripts\executor.vbs" "ATIVACAO"^</Arguments^>
>>"%XML1%" echo     ^</Exec^>
>>"%XML1%" echo   ^</Actions^>
>>"%XML1%" echo ^</Task^>

schtasks /create /tn "Monitor de Uso - Ativacao" /xml "%XML1%" /f >nul
if %errorlevel%==0 (echo [OK] Tarefa criada: Ativacao) else (echo [ERRO] Falha na tarefa Ativacao)
del "%XML1%" >nul 2>&1

:: ============================================================
:: Tarefa INATIVACAO  (disparadores: SessionLock + RemoteDisconnect)
:: ============================================================
set "XML2=%TEMP%\mu_inativ.xml"
> "%XML2%" echo ^<?xml version="1.0" encoding="UTF-16"?^>
>>"%XML2%" echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
>>"%XML2%" echo   ^<Triggers^>
>>"%XML2%" echo     ^<SessionStateChangeTrigger^>
>>"%XML2%" echo       ^<Enabled^>true^</Enabled^>
>>"%XML2%" echo       ^<StateChange^>SessionLock^</StateChange^>
>>"%XML2%" echo     ^</SessionStateChangeTrigger^>
>>"%XML2%" echo     ^<SessionStateChangeTrigger^>
>>"%XML2%" echo       ^<Enabled^>true^</Enabled^>
>>"%XML2%" echo       ^<StateChange^>RemoteDisconnect^</StateChange^>
>>"%XML2%" echo     ^</SessionStateChangeTrigger^>
>>"%XML2%" echo   ^</Triggers^>
>>"%XML2%" echo   ^<Principals^>
>>"%XML2%" echo     ^<Principal id="Author"^>
>>"%XML2%" echo       ^<LogonType^>InteractiveToken^</LogonType^>
>>"%XML2%" echo       ^<RunLevel^>LeastPrivilege^</RunLevel^>
>>"%XML2%" echo     ^</Principal^>
>>"%XML2%" echo   ^</Principals^>
>>"%XML2%" echo   ^<Settings^>
>>"%XML2%" echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
>>"%XML2%" echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
>>"%XML2%" echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
>>"%XML2%" echo     ^<Hidden^>true^</Hidden^>
>>"%XML2%" echo     ^<ExecutionTimeLimit^>PT1M^</ExecutionTimeLimit^>
>>"%XML2%" echo   ^</Settings^>
>>"%XML2%" echo   ^<Actions Context="Author"^>
>>"%XML2%" echo     ^<Exec^>
>>"%XML2%" echo       ^<Command^>wscript.exe^</Command^>
>>"%XML2%" echo       ^<Arguments^>//nologo "%~dp0scripts\executor.vbs" "INATIVACAO"^</Arguments^>
>>"%XML2%" echo     ^</Exec^>
>>"%XML2%" echo   ^</Actions^>
>>"%XML2%" echo ^</Task^>

schtasks /create /tn "Monitor de Uso - Inativacao" /xml "%XML2%" /f >nul
if %errorlevel%==0 (echo [OK] Tarefa criada: Inativacao) else (echo [ERRO] Falha na tarefa Inativacao)
del "%XML2%" >nul 2>&1

:: Pasta relatorios
if not exist "%~dp0relatorios\" mkdir "%~dp0relatorios"
echo [OK] Pasta relatorios\ pronta.

echo.
echo  Instalacao concluida!
echo  Relatorios em: %~dp0relatorios\
echo  Para alterar o nome: edite config.ini
echo.
pause
