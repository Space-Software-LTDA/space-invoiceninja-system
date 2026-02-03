# Script PowerShell para testar os Dockerfiles
# Execute: .\testar-dockerfiles.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TESTE DE DOCKERFILES - InvoiceNinja" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Docker está rodando
Write-Host "Verificando Docker..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    Write-Host "✓ Docker está rodando" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker não está rodando! Inicie o Docker Desktop primeiro." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Escolha qual Dockerfile testar:" -ForegroundColor Yellow
Write-Host "1. Dockerfile.local (código-fonte, SEM React)" -ForegroundColor White
Write-Host "2. Dockerfile.from-source (código-fonte, SEM React)" -ForegroundColor White
Write-Host "3. Dockerfile.test-hybrid (release + customizações, COM React)" -ForegroundColor Green
Write-Host "4. Testar todos" -ForegroundColor Cyan
Write-Host ""

$escolha = Read-Host "Digite o número da opção"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

switch ($escolha) {
    "1" {
        Write-Host "`n🔨 Construindo Dockerfile.local..." -ForegroundColor Yellow
        docker build -f Dockerfile.local -t invoiceninja:test-local-$timestamp .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✓ Build concluído com sucesso!" -ForegroundColor Green
            Write-Host "`nPara testar o container:" -ForegroundColor Cyan
            Write-Host "  docker run -it invoiceninja:test-local-$timestamp sh" -ForegroundColor White
            Write-Host "`nPara verificar suas customizações:" -ForegroundColor Cyan
            Write-Host "  docker run invoiceninja:test-local-$timestamp grep 'payment_type_PIX' /var/www/html/lang/pt_BR/texts.php" -ForegroundColor White
        } else {
            Write-Host "`n✗ Build falhou!" -ForegroundColor Red
        }
    }
    
    "2" {
        Write-Host "`n🔨 Construindo Dockerfile.from-source..." -ForegroundColor Yellow
        docker build -f Dockerfile.from-source -t invoiceninja:test-source-$timestamp .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✓ Build concluído com sucesso!" -ForegroundColor Green
            Write-Host "`nPara testar o container:" -ForegroundColor Cyan
            Write-Host "  docker run -it invoiceninja:test-source-$timestamp sh" -ForegroundColor White
        } else {
            Write-Host "`n✗ Build falhou!" -ForegroundColor Red
        }
    }
    
    "3" {
        Write-Host "`n🔨 Construindo Dockerfile.test-hybrid..." -ForegroundColor Yellow
        Write-Host "Este pode demorar alguns minutos (baixa o release do GitHub)..." -ForegroundColor Yellow
        docker build -f Dockerfile.test-hybrid -t invoiceninja:test-hybrid-$timestamp .
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✓ Build concluído com sucesso!" -ForegroundColor Green
            Write-Host "`nPara testar o container:" -ForegroundColor Cyan
            Write-Host "  docker run -it invoiceninja:test-hybrid-$timestamp sh" -ForegroundColor White
            Write-Host "`nPara verificar suas customizações:" -ForegroundColor Cyan
            Write-Host "  docker run invoiceninja:test-hybrid-$timestamp grep 'payment_type_PIX' /var/www/html/lang/pt_BR/texts.php" -ForegroundColor White
            Write-Host "`nPara verificar se React está compilado:" -ForegroundColor Cyan
            Write-Host "  docker run invoiceninja:test-hybrid-$timestamp ls -la /var/www/html/public/react/" -ForegroundColor White
        } else {
            Write-Host "`n✗ Build falhou!" -ForegroundColor Red
        }
    }
    
    "4" {
        Write-Host "`n🔨 Testando TODOS os Dockerfiles..." -ForegroundColor Yellow
        Write-Host ""
        
        # Teste 1
        Write-Host "[1/3] Dockerfile.local..." -ForegroundColor Cyan
        docker build -f Dockerfile.local -t invoiceninja:test-local-$timestamp . 2>&1 | Select-String -Pattern "Step|Successfully|ERROR" | ForEach-Object { Write-Host $_ }
        
        # Teste 2
        Write-Host "`n[2/3] Dockerfile.from-source..." -ForegroundColor Cyan
        docker build -f Dockerfile.from-source -t invoiceninja:test-source-$timestamp . 2>&1 | Select-String -Pattern "Step|Successfully|ERROR" | ForEach-Object { Write-Host $_ }
        
        # Teste 3
        Write-Host "`n[3/3] Dockerfile.test-hybrid..." -ForegroundColor Cyan
        Write-Host "Este pode demorar (baixa release do GitHub)..." -ForegroundColor Yellow
        docker build -f Dockerfile.test-hybrid -t invoiceninja:test-hybrid-$timestamp . 2>&1 | Select-String -Pattern "Step|Successfully|ERROR" | ForEach-Object { Write-Host $_ }
        
        Write-Host "`n✓ Todos os builds concluídos!" -ForegroundColor Green
        Write-Host "`nImagens criadas:" -ForegroundColor Cyan
        docker images | Select-String "invoiceninja:test"
    }
    
    default {
        Write-Host "Opção inválida!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Teste concluído!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
