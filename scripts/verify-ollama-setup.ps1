#!/usr/bin/env pwsh
# Local LLM Docker Setup Verification Script
# Checks Ollama, LM Studio, and Docker configuration

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Local LLM Docker Setup Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Colors
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

# Get LM Studio port from env (default 14321)
$lmStudioUrl = "http://localhost:14321"
if (Test-Path .env) {
    $envContent = Get-Content .env -Raw
    if ($envContent -match "LMSTUDIO_BASE_URL=http://[^:]+:(\d+)") {
        $lmStudioPort = $matches[1]
        $lmStudioUrl = "http://localhost:$lmStudioPort"
    }
}

# Check 1: Ollama running on host
Write-Host "[1/7] Checking Ollama on host..." -ForegroundColor $Cyan
$ollamaHost = $null
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -Method GET -TimeoutSec 5
    $ollamaHost = $response
    Write-Host "  ✓ Ollama is running on localhost:11434" -ForegroundColor $Green
    Write-Host "  Found models:" -ForegroundColor $Green
    foreach ($model in $response.models) {
        Write-Host "    - $($model.name)" -ForegroundColor $Green
    }
} catch {
    Write-Host "  ✗ Cannot connect to Ollama on localhost:11434" -ForegroundColor $Red
    Write-Host "  Make sure Ollama is running: 'ollama serve'" -ForegroundColor $Yellow
}
Write-Host ""

# Check 2: LM Studio running on host
Write-Host "[2/7] Checking LM Studio on host ($lmStudioUrl)..." -ForegroundColor $Cyan
$lmStudioHost = $null
try {
    $response = Invoke-RestMethod -Uri "$lmStudioUrl/v1/models" -Method GET -TimeoutSec 5
    $lmStudioHost = $response
    Write-Host "  ✓ LM Studio is running on $lmStudioUrl" -ForegroundColor $Green
    Write-Host "  Found models:" -ForegroundColor $Green
    foreach ($model in $response.data) {
        Write-Host "    - $($model.id)" -ForegroundColor $Green
    }
} catch {
    Write-Host "  ✗ Cannot connect to LM Studio on $lmStudioUrl" -ForegroundColor $Red
    Write-Host "  Make sure LM Studio is running and server is started" -ForegroundColor $Yellow
    Write-Host "  Also ensure CORS is enabled in LM Studio settings" -ForegroundColor $Yellow
}
Write-Host ""

# Check 3: Docker running
Write-Host "[3/7] Checking Docker..." -ForegroundColor $Cyan
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Docker is running" -ForegroundColor $Green
    } else {
        Write-Host "  ✗ Docker is not running" -ForegroundColor $Red
        exit 1
    }
} catch {
    Write-Host "  ✗ Docker is not installed or not running" -ForegroundColor $Red
    exit 1
}
Write-Host ""

# Check 4: Configuration files exist
Write-Host "[4/7] Checking configuration files..." -ForegroundColor $Cyan
$files = @(
    @(".env", $true),
    @("ai-models.json", $true),
    @("docker-compose.yml", $true)
)
foreach ($file in $files) {
    $path = $file[0]
    $required = $file[1]
    if (Test-Path $path) {
        Write-Host "  ✓ $path exists" -ForegroundColor $Green
    } elseif ($required) {
        Write-Host "  ✗ $path missing (REQUIRED)" -ForegroundColor $Red
    } else {
        Write-Host "  ! $path missing (optional)" -ForegroundColor $Yellow
    }
}
Write-Host ""

# Check 5: Environment variables
Write-Host "[5/7] Checking .env configuration..." -ForegroundColor $Cyan
$envContent = Get-Content ".env" -Raw
$checks = @(
    @("ALLOW_PRIVATE_URLS=true", "Private URLs allowed (required for local LLMs)"),
    @("OLLAMA_BASE_URL", "Ollama base URL configured"),
    @("LMSTUDIO_BASE_URL", "LM Studio base URL configured"),
    @("AI_MODELS_CONFIG_PATH", "Multi-model config path set")
)
foreach ($check in $checks) {
    $pattern = $check[0]
    $desc = $check[1]
    if ($envContent -match $pattern) {
        Write-Host "  ✓ $desc" -ForegroundColor $Green
    } else {
        Write-Host "  ✗ $desc - MISSING" -ForegroundColor $Red
    }
}
Write-Host ""

# Check 6: Docker containers
Write-Host "[6/7] Checking Docker containers..." -ForegroundColor $Cyan
$containers = docker-compose ps --services 2>$null
if ($LASTEXITCODE -eq 0 -and $containers) {
    Write-Host "  Docker Compose services:" -ForegroundColor $Green
    docker-compose ps
    
    # Check if next-ai-draw-io is running
    $appRunning = docker-compose ps | Select-String "next-ai-draw-io.*Up"
    if ($appRunning) {
        Write-Host "  ✓ next-ai-draw-io container is running" -ForegroundColor $Green
    } else {
        Write-Host "  ✗ next-ai-draw-io container is not running" -ForegroundColor $Red
        Write-Host "  Run: docker-compose up -d" -ForegroundColor $Yellow
    }
} else {
    Write-Host "  ! No containers running. Start with: docker-compose up -d" -ForegroundColor $Yellow
}
Write-Host ""

# Check 7: Test from inside container
Write-Host "[7/7] Testing LLM APIs from inside container..." -ForegroundColor $Cyan

# Test Ollama
if ($ollamaHost) {
    try {
        $result = docker-compose exec -T next-ai-draw-io sh -c "curl -s http://host.docker.internal:11434/api/tags" 2>&1
        if ($LASTEXITCODE -eq 0 -and $result) {
            Write-Host "  ✓ Container can reach Ollama" -ForegroundColor $Green
        } else {
            Write-Host "  ✗ Container cannot reach Ollama" -ForegroundColor $Red
        }
    } catch {
        Write-Host "  ✗ Failed to test Ollama from container" -ForegroundColor $Red
    }
} else {
    Write-Host "  ! Skipping Ollama test (not running on host)" -ForegroundColor $Yellow
}

# Test LM Studio
if ($lmStudioHost) {
    try {
        $result = docker-compose exec -T next-ai-draw-io sh -c "curl -s http://host.docker.internal:14321/v1/models" 2>&1
        if ($LASTEXITCODE -eq 0 -and $result) {
            Write-Host "  ✓ Container can reach LM Studio" -ForegroundColor $Green
        } else {
            Write-Host "  ✗ Container cannot reach LM Studio" -ForegroundColor $Red
            Write-Host "    Try: docker-compose exec next-ai-draw-io sh -c \"curl -v http://host.docker.internal:14321/v1/models\"" -ForegroundColor $Yellow
        }
    } catch {
        Write-Host "  ✗ Failed to test LM Studio from container" -ForegroundColor $Red
    }
} else {
    Write-Host "  ! Skipping LM Studio test (not running on host)" -ForegroundColor $Yellow
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor $Cyan
Write-Host "Summary & Next Steps" -ForegroundColor $Cyan
Write-Host "========================================" -ForegroundColor $Cyan
Write-Host ""

$hasLocalLLM = $ollamaHost -or $lmStudioHost
if ($hasLocalLLM) {
    Write-Host "✓ Local LLM(s) detected on host" -ForegroundColor $Green
    if ($ollamaHost) {
        Write-Host "  - Ollama: http://localhost:11434" -ForegroundColor $Green
    }
    if ($lmStudioHost) {
        Write-Host "  - LM Studio: $lmStudioUrl" -ForegroundColor $Green
    }
    Write-Host ""
    Write-Host "To start the application:" -ForegroundColor $Cyan
    Write-Host "  1. docker-compose up -d" -ForegroundColor White
    Write-Host "  2. Open http://localhost:3201" -ForegroundColor White
    Write-Host "  3. Click Settings → API Keys & Models" -ForegroundColor White
    Write-Host "  4. Select your provider:" -ForegroundColor White
    if ($ollamaHost) {
        Write-Host "     - Ollama Local → for Ollama models" -ForegroundColor White
    }
    if ($lmStudioHost) {
        Write-Host "     - LM Studio → for LM Studio models" -ForegroundColor White
    }
} else {
    Write-Host "✗ No local LLM detected. Please start one:" -ForegroundColor $Red
    Write-Host "  Option 1: ollama serve" -ForegroundColor White
    Write-Host "  Option 2: Start LM Studio and click 'Start Server'" -ForegroundColor White
}
Write-Host ""
Write-Host "For troubleshooting, see: docs/en/ollama-docker-setup.md" -ForegroundColor $Cyan
