#!/bin/bash
set -e
cd /var/www/html

# Flags (definidas nas variáveis de ambiente do EasyPanel)
#   IN_QUEUE_WORKER=true  -> roda o worker da fila (QUEUE_CONNECTION=database)
#   IN_SCHEDULER=true     -> roda o agendador (faturas recorrentes, lembretes...)
#                            Só UM agendador por banco, senão gera fatura duplicada!
#   RUN_MIGRATIONS=true   -> roda as migrações do banco ao iniciar
export IN_QUEUE_WORKER="${IN_QUEUE_WORKER:-false}"
export IN_SCHEDULER="${IN_SCHEDULER:-false}"
RUN_MIGRATIONS="${RUN_MIGRATIONS:-false}"

artisan() {
    runuser -u www-data -- php artisan "$@"
}

# Sincronizar os assets do release com o volume de public/ (senão a interface
# continua na versão antiga após atualizar a imagem)
cp -a /opt/invoiceninja-public/. public/

# Estrutura do storage (o volume pode vir vazio)
mkdir -p storage/app/public storage/framework/cache/data storage/framework/sessions \
    storage/framework/views storage/logs bootstrap/cache

# Link public/storage -> storage/app/public (arquivos enviados: logos, documentos)
if [ ! -L public/storage ]; then
    if [ -d public/storage ]; then
        # Pasta real (instalação antiga): move o conteúdo sem sobrescrever nada
        cp -an public/storage/. storage/app/public/
        mv public/storage "public/storage.old-$(date +%Y%m%d%H%M%S)"
    fi
    ln -s /var/www/html/storage/app/public public/storage
fi

chown -R www-data:www-data storage bootstrap/cache public

# Limpar cache do Laravel (não crítico se falhar)
artisan config:clear || true
artisan cache:clear || true
artisan view:clear || true
artisan route:clear || true

if [ "$RUN_MIGRATIONS" = "true" ]; then
    artisan migrate --force
fi

echo "InvoiceNinja $(cat VERSION.txt) | fila=$IN_QUEUE_WORKER agendador=$IN_SCHEDULER migracoes=$RUN_MIGRATIONS"

exec "$@"
