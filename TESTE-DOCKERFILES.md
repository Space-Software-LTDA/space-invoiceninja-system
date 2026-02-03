# 🧪 Guia de Teste dos Dockerfiles

## ⚠️ IMPORTANTE: Problema Atual

Ambos os Dockerfiles (`Dockerfile.local` e `Dockerfile.from-source`) **NÃO compilam o React** porque essa parte está comentada.

Eles só compilam os assets JS/CSS do Laravel (`npm run production`), mas **não o frontend React**.

## 📋 Opções de Teste

### 🎯 Opção 1: Teste Rápido (Sem React - vai dar erro de tela branca)

Teste apenas se o código-fonte está sendo copiado corretamente:

```powershell
# Teste Dockerfile.local
docker build -f Dockerfile.local -t invoiceninja:test-local .

# Teste Dockerfile.from-source  
docker build -f Dockerfile.from-source -t invoiceninja:test-source .
```

**Resultado esperado:** Build vai funcionar, mas ao acessar vai mostrar tela branca (falta React).

**Como verificar se suas customizações estão lá:**
```powershell
# Entrar no container
docker run -it invoiceninja:test-local sh

# Verificar se sua customização está presente
grep -n "payment_type_PIX" /var/www/html/lang/pt_BR/texts.php
```

---

### 🎯 Opção 2: Teste Completo (Com React - Solução Híbrida)

**Estratégia:** Baixar o release oficial APENAS para copiar o React, depois aplicar suas customizações.

#### Passo 1: Criar Dockerfile de teste híbrido

Crie um arquivo `Dockerfile.test-hybrid` que:
1. Baixa o release oficial
2. Copia o React compilado
3. Depois copia seu código-fonte (sobrescrevendo com suas customizações)

#### Passo 2: Build e teste

```powershell
docker build -f Dockerfile.test-hybrid -t invoiceninja:test-hybrid .
```

---

### 🎯 Opção 3: Teste com React do Release (Recomendado para produção)

**Estratégia:** Usar o Dockerfile atual que baixa o release, mas depois aplicar suas customizações via volume ou script.

---

## 🔍 Como Verificar se Funcionou

### 1. Verificar se o build completou:
```powershell
docker images | grep invoiceninja
```

### 2. Verificar se suas customizações estão no container:
```powershell
docker run -it invoiceninja:test-local sh
cat /var/www/html/lang/pt_BR/texts.php | grep "payment_type_PIX"
```

### 3. Verificar se o React está compilado:
```powershell
docker run -it invoiceninja:test-local sh
ls -la /var/www/html/public/react/
# Se existir arquivos .js aqui, React está compilado
```

### 4. Testar rodando o container:
```powershell
# Criar docker-compose.yml de teste
docker-compose up -d

# Ver logs
docker-compose logs -f
```

---

## 🚀 Próximos Passos

Depois de testar, você precisa decidir:

1. **Se quer manter customizações:** Use Dockerfile híbrido (baixa React do release + aplica suas customizações)
2. **Se não precisa de customizações:** Use Dockerfile padrão (só baixa release)
3. **Se quer build completo:** Configure acesso ao repositório UI do InvoiceNinja

---

## 📝 Notas

- O build pode demorar bastante (10-20 minutos) na primeira vez
- Você precisa ter Docker instalado e rodando
- Certifique-se de estar no diretório do projeto antes de rodar os comandos
