# 🚀 Build Rápido - Usando Cache do Docker

## Como Funciona o Cache do Docker

O Docker **automaticamente** usa cache de layers (camadas). Se você mudou apenas o `docker-entrypoint.sh`, ele vai:

1. ✅ Reutilizar todas as layers anteriores (baixar release, instalar dependências, etc.)
2. ✅ Reconstruir apenas a partir da linha que mudou
3. ⚡ **Muito mais rápido!**

## Uso Rápido

### Build com cache (recomendado):
```powershell
.\build-rapido.ps1
```

### Build sem cache (rebuild completo):
```powershell
.\build-rapido.ps1 -NoCache
```

### Build com tag customizada:
```powershell
.\build-rapido.ps1 -Tag "invoiceninja:minha-versao"
```

### Build com Dockerfile diferente:
```powershell
.\build-rapido.ps1 -Dockerfile "Dockerfile.local"
```

## Exemplos Práticos

### Você mudou apenas `docker-entrypoint.sh`:
```powershell
.\build-rapido.ps1
# ⚡ Muito rápido! Usa cache de tudo exceto a última parte
```

### Você mudou `lang/pt_BR/texts.php`:
```powershell
.\build-rapido.ps1
# ⚡ Rápido! Reconstrói apenas a partir do COPY . .
```

### Você mudou dependências (composer.json ou package.json):
```powershell
.\build-rapido.ps1
# ⚠️  Mais lento, precisa reinstalar dependências
```

### Você quer rebuild completo (sem cache):
```powershell
.\build-rapido.ps1 -NoCache
# 🐌 Lento! Reconstrói tudo do zero
```

## Comandos Manuais

Se preferir fazer manualmente:

```powershell
# Build com cache (padrão)
docker build -f Dockerfile.test-hybrid -t invoiceninja:test-hybrid .

# Build sem cache
docker build --no-cache -f Dockerfile.test-hybrid -t invoiceninja:test-hybrid .
```

## Dicas

1. **Cache funciona melhor quando:**
   - Você muda apenas arquivos de código
   - Você não muda `composer.json` ou `package.json`
   - Você não muda o início do Dockerfile

2. **Cache não funciona quando:**
   - Você usa `--no-cache`
   - Você muda a ordem das instruções no Dockerfile
   - Você muda arquivos que estão no início do Dockerfile

3. **Ver cache sendo usado:**
   - Procure por `CACHED` na saída do build
   - Exemplo: `=> CACHED [5/10] COPY composer.json ...`

4. **Limpar cache (se necessário):**
   ```powershell
   docker builder prune
   ```
