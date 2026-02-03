# Script para verificar se o build do Dockerfile.test-hybrid funcionou

param(
    [string]$ImageTag = "invoiceninja:test-hybrid"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  VERIFICAÇÃO DO BUILD" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se a imagem existe
Write-Host "1️⃣ Verificando se a imagem existe..." -ForegroundColor Yellow
$imageExists = docker images $ImageTag --format "{{.Repository}}:{{.Tag}}" 2>&1 | Select-String $ImageTag

if ($imageExists) {
    Write-Host "   ✅ Imagem encontrada: $ImageTag" -ForegroundColor Green
} else {
    Write-Host "   ❌ Imagem não encontrada!" -ForegroundColor Red
    Write-Host "   Execute: docker build -f Dockerfile.test-hybrid -t $ImageTag ." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "2️⃣ Verificando React em public/react/..." -ForegroundColor Yellow
$reactFiles = docker run --rm $ImageTag find /var/www/html/public/react -type f 2>&1 | Measure-Object -Line
if ($reactFiles.Lines -gt 1) {
    Write-Host "   ✅ React encontrado: $($reactFiles.Lines) arquivos" -ForegroundColor Green
    docker run --rm $ImageTag ls -la /var/www/html/public/react/ 2>&1 | Select-Object -First 10 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "   ❌ React não encontrado ou incompleto!" -ForegroundColor Red
}

Write-Host ""
Write-Host "3️⃣ Verificando resources/views/react/..." -ForegroundColor Yellow
$headExists = docker run --rm $ImageTag test -f /var/www/html/resources/views/react/head.blade.php 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ head.blade.php encontrado" -ForegroundColor Green
    Write-Host "   Conteúdo (primeiras 5 linhas):" -ForegroundColor Gray
    docker run --rm $ImageTag head -5 /var/www/html/resources/views/react/head.blade.php 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "   ❌ head.blade.php NÃO encontrado!" -ForegroundColor Red
}

Write-Host ""
Write-Host "4️⃣ Verificando suas customizações..." -ForegroundColor Yellow
$customExists = docker run --rm $ImageTag grep -q "payment_type_PIX" /var/www/html/lang/pt_BR/texts.php 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Customização encontrada (payment_type_PIX)" -ForegroundColor Green
    docker run --rm $ImageTag grep "payment_type_PIX" /var/www/html/lang/pt_BR/texts.php 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
} else {
    Write-Host "   ⚠️  Customização não encontrada" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "5️⃣ Verificando estrutura geral..." -ForegroundColor Yellow
Write-Host "   Arquivos importantes:" -ForegroundColor Gray
docker run --rm $ImageTag ls -la /var/www/html/ 2>&1 | Select-String -Pattern "public|resources|lang|app" | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESUMO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para testar rodando o container:" -ForegroundColor Cyan
Write-Host "  docker run -d -p 9000:9000 --name test-invoiceninja $ImageTag" -ForegroundColor White
Write-Host ""
Write-Host "Para entrar no container:" -ForegroundColor Cyan
Write-Host "  docker exec -it test-invoiceninja sh" -ForegroundColor White
Write-Host ""
Write-Host "Para ver logs:" -ForegroundColor Cyan
Write-Host "  docker logs test-invoiceninja" -ForegroundColor White
Write-Host ""
Write-Host "Para parar e remover:" -ForegroundColor Cyan
Write-Host "  docker stop test-invoiceninja && docker rm test-invoiceninja" -ForegroundColor White
