# 🔍 Como Verificar se o Build Funcionou

## Método Rápido (Script)

```powershell
.\verificar-build.ps1
```

O script verifica automaticamente:
- ✅ Se a imagem foi criada
- ✅ Se o React está presente
- ✅ Se `head.blade.php` existe
- ✅ Se suas customizações estão lá

---

## Método Manual

### 1. Verificar se a imagem existe

```powershell
docker images invoiceninja:test-hybrid
```

### 2. Verificar React em `public/react/`

```powershell
# Ver arquivos
docker run --rm invoiceninja:test-hybrid ls -la /var/www/html/public/react/

# Contar arquivos
docker run --rm invoiceninja:test-hybrid find /var/www/html/public/react -type f | wc -l

# Ver tamanho
docker run --rm invoiceninja:test-hybrid du -sh /var/www/html/public/react
```

**Esperado:** Muitos arquivos `.js`, `.css`, etc. (não apenas 1 arquivo!)

### 3. Verificar `resources/views/react/head.blade.php`

```powershell
# Verificar se existe
docker run --rm invoiceninja:test-hybrid test -f /var/www/html/resources/views/react/head.blade.php && echo "✅ Existe" || echo "❌ Não existe"

# Ver conteúdo
docker run --rm invoiceninja:test-hybrid head -10 /var/www/html/resources/views/react/head.blade.php
```

**Esperado:** Arquivo com conteúdo (scripts e links CSS)

### 4. Verificar suas customizações

```powershell
# Verificar se sua customização está lá
docker run --rm invoiceninja:test-hybrid grep "payment_type_PIX" /var/www/html/lang/pt_BR/texts.php
```

**Esperado:** Linha com `'payment_type_PIX' => 'PIX'`

---

## Testar Rodando o Container

### Opção 1: Container temporário (teste rápido)

```powershell
# Rodar em background
docker run -d -p 9000:9000 --name test-invoiceninja invoiceninja:test-hybrid

# Ver logs
docker logs test-invoiceninja

# Entrar no container
docker exec -it test-invoiceninja sh

# Parar e remover
docker stop test-invoiceninja
docker rm test-invoiceninja
```

### Opção 2: Com docker-compose

Crie um `docker-compose.test.yml`:

```yaml
version: '3.8'
services:
  invoiceninja:
    build:
      context: .
      dockerfile: Dockerfile.test-hybrid
    container_name: test-invoiceninja
    ports:
      - "9000:9000"
    volumes:
      - ./storage:/var/www/html/storage
```

Depois:

```powershell
docker-compose -f docker-compose.test.yml up -d
docker-compose -f docker-compose.test.yml logs -f
```

---

## Verificar no Navegador

Se você tem um servidor web (nginx/apache) configurado:

1. Configure o servidor para usar o container PHP-FPM na porta 9000
2. Acesse a aplicação no navegador
3. **Se funcionar:** Você verá a interface do InvoiceNinja (não tela branca)
4. **Se não funcionar:** Você verá a mensagem HTML sobre React não carregado

---

## Checklist de Sucesso ✅

- [ ] Imagem Docker criada sem erros
- [ ] `public/react/` tem muitos arquivos (não apenas 1)
- [ ] `resources/views/react/head.blade.php` existe e tem conteúdo
- [ ] Suas customizações estão presentes (`lang/pt_BR/texts.php`)
- [ ] Container inicia sem erros
- [ ] Aplicação carrega no navegador (sem tela branca)

---

## Problemas Comuns

### ❌ React tem apenas 1 arquivo
**Causa:** `public/react/` foi sobrescrito ou não foi preservado  
**Solução:** Verifique se `.dockerignore` tem `public/` e `resources/views/react/`

### ❌ `head.blade.php` não existe
**Causa:** `resources/views/react/` foi sobrescrito  
**Solução:** Adicione `resources/views/react/` ao `.dockerignore`

### ❌ Tela branca no navegador
**Causa:** React não está completo ou `head.blade.php` está vazio  
**Solução:** Verifique os logs do build e confirme que React foi preservado

### ❌ Customizações não aparecem
**Causa:** Arquivos foram sobrescritos pelo release  
**Solução:** Verifique se o `COPY . .` está copiando seus arquivos customizados

---

## Comandos Úteis

```powershell
# Ver tudo que está no container
docker run --rm invoiceninja:test-hybrid ls -la /var/www/html/

# Comparar com Dockerfile padrão
docker build -f Dockerfile -t invoiceninja:prod .
docker run --rm invoiceninja:prod ls -la /var/www/html/public/react/ | head -20
docker run --rm invoiceninja:test-hybrid ls -la /var/www/html/public/react/ | head -20

# Ver diferenças
docker run --rm invoiceninja:prod cat /var/www/html/resources/views/react/head.blade.php > head-prod.txt
docker run --rm invoiceninja:test-hybrid cat /var/www/html/resources/views/react/head.blade.php > head-test.txt
diff head-prod.txt head-test.txt
```
