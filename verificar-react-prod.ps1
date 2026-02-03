# Script para verificar estrutura do React no Dockerfile padrão (que funciona)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verificando React no Dockerfile Padrão" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔨 Construindo imagem com Dockerfile padrão..." -ForegroundColor Yellow
docker build -f Dockerfile -t invoiceninja:prod-check .

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build concluído!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔍 Verificando estrutura do React..." -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "1. Verificando se public/react existe:" -ForegroundColor Yellow
    docker run --rm invoiceninja:prod-check ls -la /var/www/html/public/ | Select-String "react"
    
    Write-Host ""
    Write-Host "2. Conteúdo de public/react/:" -ForegroundColor Yellow
    docker run --rm invoiceninja:prod-check ls -la /var/www/html/public/react/ 2>&1 | Select-Object -First 30
    
    Write-Host ""
    Write-Host "3. Quantidade de arquivos em public/react/:" -ForegroundColor Yellow
    docker run --rm invoiceninja:prod-check find /var/www/html/public/react -type f 2>&1 | Measure-Object -Line
    
    Write-Host ""
    Write-Host "4. Tamanho total de public/react/:" -ForegroundColor Yellow
    docker run --rm invoiceninja:prod-check du -sh /var/www/html/public/react 2>&1
    
    Write-Host ""
    Write-Host "5. Procurando por arquivos React em public/:" -ForegroundColor Yellow
    docker run --rm invoiceninja:prod-check find /var/www/html/public -name "*react*" -o -name "index-*.js" 2>&1 | Select-Object -First 20
    
    Write-Host ""
    Write-Host "6. Estrutura completa de public/ (primeiros 50 itens):" -ForegroundColor Yellow
    docker run --rm invoiceninja:prod-check ls -la /var/www/html/public/ 2>&1 | Select-Object -First 50
    
} else {
    Write-Host ""
    Write-Host "❌ Build falhou!" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verificação concluída!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
