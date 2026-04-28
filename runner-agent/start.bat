@echo off
REM QA Test Suite - Runner Agent Launcher (Batch)
REM Inicia el backend del Runner Agent (agent.js)

setlocal enabledelayedexpansion

set "AGENT_DIR=%~dp0"
set "SCRIPT_PS=%AGENT_DIR%start.ps1"

title QA Test Suite - Runner Agent

cls
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║     QA Test Suite - Runner Agent Launcher                 ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Verificar que PowerShell está disponible
powershell.exe -Version >nul 2>&1
if errorlevel 1 (
    echo [!] ERROR: PowerShell no está disponible
    pause
    exit /b 1
)

REM Ejecutar el script PowerShell
echo [*] Ejecutando Runner Agent...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PS%"

endlocal
pause

