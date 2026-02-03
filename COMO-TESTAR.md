# 🚀 Como Testar os Dockerfiles

## Método Rápido (Recomendado)

Execute o script PowerShell:

```powershell
.\testar-dockerfiles.ps1
```

O script vai:
- Verificar se Docker está rodando
- Mostrar opções de teste
- Construir a imagem escolhida
- Mostrar comandos para verificar o resultado

---

## Método Manual

### 1️⃣ Teste Dockerfile.local (código-fonte, SEM React)

```powershell
docker build -f Dockerfile.local -t invoiceninja:test-local .
```

**Verificar customizações:**
```powershell
docker run invoiceninja:test-local grep "payment_type_PIX" /var/www/html/lang/pt_BR/texts.php
```

**⚠️ Resultado:** Build funciona, mas React não está compilado (tela branca ao acessar)

---

### 2️⃣ Teste Dockerfile.from-source (código-fonte, SEM React)

```powershell
docker build -f Dockerfile.from-source -t invoiceninja:test-source .
```

**⚠️ Resultado:** Mesmo que o anterior - React não compilado

---

### 3️⃣ Teste Dockerfile.test-hybrid (RECOMENDADO ✅)

Este é o melhor! Baixa o release oficial (com React) e depois aplica suas customizações.

```powershell
docker build -f Dockerfile.test-hybrid -t invoiceninja:test-hybrid .
```

**Verificar customizações:**
```powershell
docker run invoiceninja:test-hybrid grep "payment_type_PIX" /var/www/html/lang/pt_BR/texts.php
```

**Verificar se React está compilado:**
```powershell
docker run invoiceninja:test-hybrid ls -la /var/www/html/public/react/
```

**✅ Resultado:** React compilado + suas customizações preservadas!

---

## Teste com Docker Compose

Para testar todos de uma vez:

```powershell
docker-compose -f docker-compose.test.yml build
docker-compose -f docker-compose.test.yml up -d
```

Depois acesse:
- Container local: porta 9001
- Container source: porta 9002  
- Container hybrid: porta 9003

---

## 🔍 Verificar Resultados

### Ver imagens criadas:
```powershell
docker images | Select-String "invoiceninja:test"
```

### Entrar no container:
```powershell
docker run -it invoiceninja:test-hybrid sh
```

### Verificar arquivo customizado:
```powershell
docker run invoiceninja:test-hybrid cat /var/www/html/lang/pt_BR/texts.php | Select-String "PIX"
```

### Verificar se React existe:
```powershell
docker run invoiceninja:test-hybrid test -d /var/www/html/public/react && echo "React existe!" || echo "React NÃO existe"
```

---

## ⚠️ Problemas Comuns

### "Docker não está rodando"
- Inicie o Docker Desktop
- Aguarde até aparecer "Docker Desktop is running"

### "Build muito lento"
- Normal! Primeira vez pode levar 10-20 minutos
- Builds seguintes serão mais rápidos (cache)

### "Erro ao baixar release"
- Verifique sua conexão com internet
- O GitHub pode estar temporariamente indisponível

### "Customizações não aparecem"
- Verifique se o arquivo `lang/pt_BR/texts.php` existe no diretório do projeto
- Verifique se o caminho no Dockerfile está correto

---

## 📝 Próximos Passos

Depois de testar:

1. **Se Dockerfile.test-hybrid funcionou:** Use ele em produção!
2. **Se precisar de mais customizações:** Adicione mais linhas `COPY` no Dockerfile.test-hybrid
3. **Se quiser build completo do React:** Configure acesso ao repositório UI do InvoiceNinja

---

## 💡 Dica

O **Dockerfile.test-hybrid** é a melhor solução porque:
- ✅ Tem React compilado (não dá tela branca)
- ✅ Mantém suas customizações
- ✅ Não precisa de token do GitHub
- ✅ Build rápido (só baixa release + aplica customizações)
