#!/bin/bash

# Aguardar até que o arquivo .env exista (se necessário)
# O EasyPanel geralmente injeta variáveis de ambiente, mas podemos verificar

# Criar link simbólico para storage se não existir
if [ ! -L public/storage ] && [ -d storage/app/public ]; then
    php artisan storage:link || true
fi

# Limpar cache do Laravel (não crítico se falhar)
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
# php artisan serve 2>/dev/null || true

# Otimizar aplicação Laravel (opcional, pode ser feito manualmente)
# php artisan config:cache || true
# php artisan route:cache || true
# php artisan view:cache || true

# Executar migrações (descomente se necessário)
# php artisan migrate --force || true

# Executar PHP-FPM
exec "$@"
