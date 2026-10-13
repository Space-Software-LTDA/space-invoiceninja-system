# Dockerfile para InvoiceNinja (EasyPanel)
# Container único: NGINX + PHP-FPM + worker de fila + agendador, via supervisord
# Usa o release oficial do GitHub com frontend React já compilado
#
# Para atualizar o InvoiceNinja: mude INVOICENINJA_VERSION abaixo e faça deploy.
# Não use "latest": a versão precisa ser reproduzível para dar rollback.

FROM php:8.3-fpm

# Variáveis de ambiente
ENV DEBIAN_FRONTEND=noninteractive \
    PHP_MEMORY_LIMIT=512M \
    PHP_UPLOAD_MAX_FILESIZE=50M \
    PHP_POST_MAX_SIZE=50M \
    INVOICENINJA_VERSION=v5.13.47

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    curl \
    wget \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libicu-dev \
    libcurl4-openssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP necessárias
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    bcmath \
    gd \
    mbstring \
    xml \
    zip \
    intl \
    opcache

# Instalar Redis extension (opcional mas recomendado)
RUN pecl install redis && docker-php-ext-enable redis

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar diretório de trabalho
WORKDIR /var/www/html

# Baixar e extrair o release oficial do InvoiceNinja
# Se INVOICENINJA_VERSION=latest, descobrir a versão mais recente primeiro
RUN if [ "$INVOICENINJA_VERSION" = "latest" ]; then \
        LATEST_VERSION=$(curl -s https://api.github.com/repos/invoiceninja/invoiceninja/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') || LATEST_VERSION="latest"; \
        DOWNLOAD_URL="https://github.com/invoiceninja/invoiceninja/releases/download/${LATEST_VERSION}/invoiceninja.tar.gz"; \
    else \
        DOWNLOAD_URL="https://github.com/invoiceninja/invoiceninja/releases/download/${INVOICENINJA_VERSION}/invoiceninja.tar.gz"; \
    fi \
    && echo "Baixando InvoiceNinja de: $DOWNLOAD_URL" \
    && curl -L --fail --retry 3 --max-time 300 -o /tmp/invoiceninja.tar.gz "$DOWNLOAD_URL" \
    && if [ ! -f /tmp/invoiceninja.tar.gz ] || [ ! -s /tmp/invoiceninja.tar.gz ]; then \
        echo "ERRO: Arquivo baixado está vazio ou não existe"; \
        exit 1; \
    fi \
    && echo "Extraindo arquivo..." \
    && mkdir -p /tmp/invoiceninja-extract \
    && tar -xzf /tmp/invoiceninja.tar.gz -C /tmp/invoiceninja-extract \
    && rm /tmp/invoiceninja.tar.gz \
    && cd /tmp/invoiceninja-extract \
    && if [ -d invoiceninja ]; then \
        echo "Copiando arquivos da pasta invoiceninja..." \
        && cp -R invoiceninja/* /var/www/html/; \
    else \
        EXTRACT_DIR=$(find . -maxdepth 1 -type d -name "invoiceninja*" | head -1); \
        if [ -n "$EXTRACT_DIR" ]; then \
            echo "Copiando arquivos de $EXTRACT_DIR..." \
            && cp -R "$EXTRACT_DIR"/* /var/www/html/; \
        else \
            echo "Copiando todos os arquivos..." \
            && cp -R . /var/www/html/; \
        fi; \
    fi \
    && rm -rf /tmp/invoiceninja-extract \
    && echo "Download e extração concluídos com sucesso!"

# Personalização: tipo de pagamento PIX (id=200). Desde a 5.13 a lista de tipos é
# fixa no código (PaymentType::getDefaultPaymentTypes), então o script adiciona o PIX
# ali, no mapa de nomes e nas traduções. Se uma versão nova mudar esse arquivo, o
# build falha aqui de propósito: ajuste docker/pix-patch.sh.
COPY docker/pix-patch.sh /tmp/pix-patch.sh
RUN sed -i 's/\r$//' /tmp/pix-patch.sh && sh /tmp/pix-patch.sh /var/www/html && rm /tmp/pix-patch.sh

# Guardar uma cópia do public/ do release: no EasyPanel /var/www/html/public é um
# volume persistente, que esconderia os assets novos. O entrypoint sincroniza a
# cópia para o volume a cada start.
RUN cp -a /var/www/html/public /opt/invoiceninja-public

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Configurar PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/;listen.owner = www-data/listen.owner = www-data/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/;listen.group = www-data/listen.group = www-data/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/user = www-data/user = www-data/' /usr/local/etc/php-fpm.d/www.conf \
    && sed -i 's/group = www-data/group = www-data/' /usr/local/etc/php-fpm.d/www.conf

# Configurar PHP.ini
RUN echo "memory_limit = ${PHP_MEMORY_LIMIT}" > /usr/local/etc/php/conf.d/memory.ini \
    && echo "upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}" > /usr/local/etc/php/conf.d/uploads.ini \
    && echo "post_max_size = ${PHP_POST_MAX_SIZE}" >> /usr/local/etc/php/conf.d/uploads.ini \
    && echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/execution.ini \
    && echo "max_input_time = 300" >> /usr/local/etc/php/conf.d/execution.ini

# Configurar OPcache para produção
RUN echo "opcache.enable=1" > /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=2" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini

# NGINX (serve o public/ e repassa PHP para o FPM local) e supervisord
RUN rm -f /etc/nginx/sites-enabled/default
COPY docker/nginx.conf /etc/nginx/conf.d/invoiceninja.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/invoiceninja.conf

# Script de inicialização
COPY docker-entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Porta HTTP (NGINX)
EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
