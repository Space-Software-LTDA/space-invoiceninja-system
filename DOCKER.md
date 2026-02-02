# Docker Setup para InvoiceNinja no EasyPanel

Este Dockerfile foi criado especificamente para uso com **EasyPanel** e **NGINX separado**.

## Características

- ✅ PHP 8.2-FPM
- ✅ Todas as extensões PHP necessárias instaladas
- ✅ Composer pré-instalado
- ✅ Otimizado para produção
- ✅ OPcache habilitado
- ✅ Configurado para trabalhar com NGINX separado

## Requisitos

- EasyPanel configurado com NGINX
- Banco de dados MySQL/MariaDB
- Redis (opcional, mas recomendado)

## Como usar no EasyPanel

### 1. Build da Imagem

No EasyPanel, configure o build do Dockerfile:

```bash
# O EasyPanel fará o build automaticamente, mas você pode testar localmente:
docker build -t invoiceninja-custom:latest .
```

### 2. Configuração no EasyPanel

1. **Criar novo aplicativo** no EasyPanel
2. **Selecionar "Docker"** como tipo de aplicativo
3. **Configurar o repositório Git** (seu repositório)
4. **Definir o Dockerfile** como caminho de build
5. **Configurar variáveis de ambiente** (veja abaixo)

### 3. Variáveis de Ambiente Necessárias

Configure estas variáveis no EasyPanel:

```env
APP_NAME="Invoice Ninja"
APP_ENV=production
APP_KEY=base64:SUA_CHAVE_AQUI
APP_DEBUG=false
APP_URL=https://seu-dominio.com

DB_CONNECTION=mysql
DB_HOST=seu-banco-host
DB_DATABASE=nome_do_banco
DB_USERNAME=usuario
DB_PASSWORD=senha
DB_PORT=3306

REDIS_HOST=seu-redis-host
REDIS_PASSWORD=senha-redis
REDIS_PORT=6379

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
BROADCAST_DRIVER=redis

NINJA_ENVIRONMENT=selfhost
```

**Importante:** Gere uma nova `APP_KEY` se necessário:
```bash
php artisan key:generate --show
```

### 4. Configuração do NGINX no EasyPanel

O NGINX já está rodando separadamente. **IMPORTANTE**: Certifique-se de que a configuração do NGINX está correta:

**Document Root**: O NGINX deve apontar para `/var/www/html/public` (não apenas `/var/www/html`)

**Configuração NGINX recomendada**:

```nginx
server {
    listen 80;
    server_name seu-dominio.com;
    
    # Document root DEVE ser /var/www/html/public
    root /var/www/html/public;
    index index.php index.html;

    # Configuração do PHP-FPM
    location ~ \.php$ {
        fastcgi_pass invoiceninja-app:9000;  # Nome do seu container PHP-FPM
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    # Redirecionar tudo para index.php (Laravel)
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Negar acesso a arquivos ocultos
    location ~ /\. {
        deny all;
    }
}
```

**No EasyPanel**, configure:
- **Document Root**: `/var/www/html/public`
- **PHP-FPM Host**: Nome do seu container (ex: `invoiceninja-app`)
- **PHP-FPM Port**: `9000`

### 5. Volumes Necessários

No EasyPanel, certifique-se de mapear os volumes necessários:

- `/var/www/html/storage` - Para armazenamento de arquivos
- `/var/www/html/bootstrap/cache` - Para cache do Laravel

### 6. Primeira Execução

Após o deploy inicial, você pode precisar executar:

```bash
# Conectar ao container
docker exec -it seu-container-name bash

# Criar link simbólico do storage (se não foi criado automaticamente)
php artisan storage:link

# Executar migrações (se necessário)
php artisan migrate --force

# Limpar cache
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
```

### 7. Otimizações (Opcional)

Para melhor performance em produção:

```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## Estrutura de Arquivos

```
.
├── Dockerfile              # Dockerfile principal
├── docker-entrypoint.sh    # Script de inicialização
├── .dockerignore          # Arquivos ignorados no build
└── DOCKER.md              # Este arquivo
```

## Troubleshooting

### Erro de permissões
```bash
# Dentro do container
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 755 /var/www/html/storage
chmod -R 755 /var/www/html/bootstrap/cache
```

### Erro de conexão com banco
- Verifique se as variáveis de ambiente estão corretas
- Verifique se o banco está acessível do container
- Teste a conexão: `php artisan tinker` e depois `DB::connection()->getPdo();`

### Cache não limpa
```bash
php artisan optimize:clear
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
```

## Notas Importantes

1. **Não inclui NGINX**: Este Dockerfile é apenas para PHP-FPM, pois o NGINX já está rodando separadamente no EasyPanel.

2. **Document Root**: ⚠️ **CRÍTICO** - O NGINX deve apontar para `/var/www/html/public` como document root, não para `/var/www/html`. O arquivo `index.php` está em `public/index.php`.

3. **Produção**: O Dockerfile está configurado para produção (`--no-dev` no composer install).

4. **OPcache**: Está habilitado e otimizado para melhor performance.

5. **Porta**: O PHP-FPM está configurado para escutar na porta **9000** (padrão).

6. **Storage**: O diretório `storage` precisa ter permissões de escrita.

7. **Estrutura de Diretórios no Container**:
   ```
   /var/www/html/              # Raiz do projeto Laravel
   ├── app/
   ├── bootstrap/
   ├── config/
   ├── public/                 # ⬅️ Document Root do NGINX deve apontar aqui
   │   └── index.php          # ⬅️ Arquivo de entrada principal
   ├── resources/
   ├── routes/
   ├── storage/
   └── vendor/
   ```

## Suporte

Para mais informações sobre o InvoiceNinja:
- [Documentação Oficial](https://invoiceninja.github.io/)
- [Fórum de Suporte](https://forum.invoiceninja.com)
