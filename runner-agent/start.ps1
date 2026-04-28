# QA Test Suite - Runner Agent Launcher
# Este script inicia el backend del Runner Agent (agent.js)

param(
    [string]$Action = "start"
)

$AgentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $AgentDir  # Sube al directorio TestQA
$LogFile = "$AgentDir\agent_startup.log"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage -ErrorAction SilentlyContinue
}

Write-Log "═══════════════════════════════════════════════════════════════"
Write-Log "QA Test Suite - Runner Agent Launcher"
Write-Log "═══════════════════════════════════════════════════════════════"
Write-Log ""

# Verificar que Node.js está instalado
Write-Host "[*] Verificando Node.js..." -ForegroundColor Yellow
$nodeVersion = & node --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: Node.js no está instalado o no está en PATH" -ForegroundColor Red
    Write-Host "    Descarga desde: https://nodejs.org/" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Node.js encontrado: $nodeVersion" -ForegroundColor Green

# Verificar que npm está instalado
Write-Host "[*] Verificando npm..." -ForegroundColor Yellow
$npmVersion = & npm --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] ERROR: npm no está instalado" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] npm encontrado: $npmVersion" -ForegroundColor Green

# Cambiar al directorio del agente
Set-Location $AgentDir
Write-Host "[*] Directorio actual: $AgentDir" -ForegroundColor Yellow

# Instalar dependencias si no existen
if (!(Test-Path "$AgentDir\node_modules")) {
    Write-Host "[*] Instalando dependencias..." -ForegroundColor Yellow
    & npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] ERROR: Falló la instalación de dependencias" -ForegroundColor Red
        exit 1
    }
    Write-Host "[✓] Dependencias instaladas" -ForegroundColor Green
}

# Verificar que .env existe
if (!(Test-Path "$AgentDir\.env")) {
    Write-Host "[!] ERROR: Archivo .env no encontrado en $AgentDir" -ForegroundColor Red
    Write-Host "    Copia .env.example a .env y configura las rutas" -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Archivo .env encontrado" -ForegroundColor Green

Write-Host ""
Write-Host "[*] Iniciando Runner Agent en puerto 4000..." -ForegroundColor Yellow
Write-Host "[*] URL: http://localhost:4000" -ForegroundColor Cyan
Write-Host "[*] Presiona Ctrl+C para detener" -ForegroundColor Yellow
Write-Host ""

# Iniciar el servidor
& node agent.js

