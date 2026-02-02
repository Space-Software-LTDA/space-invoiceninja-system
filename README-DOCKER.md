# 🐳 Guia de Dockerfiles - InvoiceNinja

Este projeto tem **3 Dockerfiles diferentes** para diferentes cenários:

## 📋 Comparação Rápida

| Dockerfile | Quando Usar | Prós | Contras |
|------------|-------------|------|---------|
| `Dockerfile` | **Produção padrão** | ✅ Rápido<br>✅ Confiável<br>✅ Sem build | ❌ Sem customizações |
| `Dockerfile.local` | **Customizações** | ✅ Controle total<br>✅ Customizações | ⚠️ Build mais lento<br>⚠️ Requer Node.js |
| `Dockerfile.from-source` | **Desenvolvimento** | ✅ Código fonte completo | ❌ Muito lento<br>❌ Requer acesso ao UI repo |

---

## 🎯 Qual Dockerfile Usar?

### ✅ Use `Dockerfile` (Padrão) se:
- Você quer apenas usar o InvoiceNinja sem modificações
- Quer builds rápidos
- Está em produção
- **Este é o recomendado para 99% dos casos**

### ⚙️ Use `Dockerfile.local` se:
- Você fez customizações no código PHP/Laravel
- Quer fazer build do React durante o Docker build
- Tem o código fonte do UI localmente ou acesso ao GitHub
- Quer controle total sobre o processo

### 🔧 Use `Dockerfile.from-source` se:
- Você está desenvolvendo features novas
- Precisa do código fonte completo
- Tem acesso ao repositório UI do InvoiceNinja

---

## ❌ Por que NÃO fazer commit de arquivos compilados?

### Problemas de fazer commit de arquivos buildados:

1. **Git fica pesado**
   - Arquivos JS compilados são grandes (MBs)
   - Cada mudança gera novos arquivos
   - Histórico do Git fica inchado

2. **Conflitos em merges**
   - Arquivos compilados mudam muito
   - Conflitos difíceis de resolver
   - Perda de tempo

3. **Não é boa prática**
   - Código fonte no Git
   - Builds devem ser feitos durante deploy
   - Separação de responsabilidades

4. **Diferenças entre ambientes**
   - Build local pode ser diferente do servidor
   - Problemas de compatibilidade
   - Debugging difícil

---

## ✅ Soluções Recomendadas

### Opção 1: Usar Release Oficial (Recomendado)
```bash
# Use o Dockerfile padrão
docker build -t invoiceninja:latest .
```

**Vantagens:**
- ✅ Build rápido
- ✅ Sempre atualizado
- ✅ Testado pelos mantenedores
- ✅ Sem problemas de build

### Opção 2: Build Durante Docker Build
```bash
# Use Dockerfile.local
docker build -f Dockerfile.local -t invoiceninja:latest .
```

**Vantagens:**
- ✅ Código fonte no Git (sem arquivos compilados)
- ✅ Build sempre consistente
- ✅ Pode fazer customizações
- ✅ Build isolado no Docker

### Opção 3: Build Local + Copiar Durante Build
Se você realmente quer compilar localmente:

1. **Compile localmente** (não faça commit):
```bash
npm run build
npm run production
```

2. **Use no Dockerfile** (os arquivos já estarão no contexto):
```dockerfile
# Os arquivos em public/ já estarão compilados
COPY . .
```

3. **Mas NÃO faça commit** - use `.dockerignore` para garantir:
```dockerignore
# Já está no .dockerignore
/public/react
/public/build
node_modules
```

---

## 🚀 Como Usar no EasyPanel

### Com Dockerfile Padrão (Recomendado):
1. Configure o repositório Git (só precisa do Dockerfile)
2. EasyPanel fará o build automaticamente
3. O Dockerfile baixa o release oficial
4. Pronto! ✅

### Com Dockerfile.local:
1. Configure o repositório Git (código fonte completo)
2. No EasyPanel, configure:
   - **Dockerfile**: `Dockerfile.local`
   - **Build Args** (se necessário): `GITHUB_TOKEN=seu_token`
3. EasyPanel fará o build completo
4. Pronto! ✅

---

## 📝 Resumo

**NÃO faça commit de arquivos compilados no Git!**

**FAÇA:**
- ✅ Commit do código fonte
- ✅ Build durante Docker build
- ✅ Use release oficial quando possível

**NÃO FAÇA:**
- ❌ Commit de `public/react/`
- ❌ Commit de `public/build/`
- ❌ Commit de `node_modules/`
- ❌ Commit de arquivos `.js` compilados grandes

---

## 🔍 Verificar o que está no Git

```bash
# Ver arquivos grandes no Git
git ls-files | xargs ls -lh | sort -k5 -hr | head -20

# Ver se há arquivos compilados
git ls-files | grep -E '\.(js|css)$' | grep -v node_modules
```

Se encontrar muitos arquivos `.js` grandes, considere adicionar ao `.gitignore`.
