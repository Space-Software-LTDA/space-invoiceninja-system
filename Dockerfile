# Dockerfile para InvoiceNinja com PHP-FPM
# Otimizado para uso com NGINX separado (EasyPanel)

FROM php:8.2-fpm

# Variáveis de ambiente
ENV DEBIAN_FRONTEND=noninteractive \
    PHP_MEMORY_LIMIT=512M \
    PHP_UPLOAD_MAX_FILESIZE=50M \
    PHP_POST_MAX_SIZE=50M

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar extensões PHP necessárias
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    bcmath \
    curl \
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

# Copiar apenas arquivos necessários para instalar dependências (melhor cache)
COPY composer.json composer.lock* ./

# Instalar dependências do Composer (sem dev para produção)
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# Copiar o resto dos arquivos do projeto
COPY . .

# Configurar permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Executar scripts pós-instalação do Composer
RUN composer dump-autoload --optimize

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

# Script de inicialização (copiar antes para melhor cache)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expor porta do PHP-FPM
EXPOSE 9000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
