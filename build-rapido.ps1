# Script para build rápido usando cache do Docker
# Use quando você fez apenas pequenas alterações

param(
    [string]$Tag = "invoiceninja:test-hybrid",
    [string]$Dockerfile = "Dockerfile.test-hybrid",
    [switch]$NoCache = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BUILD RÁPIDO - Docker Cache" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($NoCache) {
    Write-Host "⚠️  Modo SEM cache (rebuild completo)" -ForegroundColor Yellow
    $buildArgs = "--no-cache"
} else {
    Write-Host "✅ Modo COM cache (build incremental)" -ForegroundColor Green
    Write-Host "   Docker vai reutilizar layers que não mudaram" -ForegroundColor Gray
    $buildArgs = ""
}

Write-Host ""
Write-Host "🔨 Construindo imagem: $Tag" -ForegroundColor Yellow
Write-Host "   Dockerfile: $Dockerfile" -ForegroundColor Gray
Write-Host ""

$startTime = Get-Date

if ($buildArgs) {
    docker build $buildArgs -f $Dockerfile -t $Tag .
} else {
    docker build -f $Dockerfile -t $Tag .
}

$endTime = Get-Date
$duration = $endTime - $startTime

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build concluído com sucesso!" -ForegroundColor Green
    Write-Host "   Tempo: $($duration.TotalSeconds.ToString('F2')) segundos" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Para testar:" -ForegroundColor Cyan
    Write-Host "  docker run $Tag" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Build falhou!" -ForegroundColor Red
    exit 1
}
