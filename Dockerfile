###
# Based on https://github.com/ambientum/ambientum/blob/master/php/7.3/Dockerfile
#
FROM alpine:3.12

# Repository/Image Maintainer
LABEL maintainer="Ben Bjurstrom <ben@jelled.com>"

# Environmental Variables
ENV OPCACHE_MODE="normal" \
    PHP_MEMORY_LIMIT=1024M \
    XDEBUG_ENABLED=false \
    TERM=xterm-256color \
    COLORTERM=truecolor \
    COMPOSER_PROCESS_TIMEOUT=1200

# Add the ENTRYPOINT script
ADD init.sh /root/init.sh
ADD crontab /root/crontab
ADD bashrc /root/.bashrc

RUN echo "---> Add System Packages" && \
    apk add --update \
    bash \
    curl \
    git \
    npm \
    sudo \
    vim \
    wget \
    yarn \
    postgresql-client \
    unzip && \

    echo "---> Adding /var/www" && \
    mkdir -p /var/www && \
    chmod +x /root/init.sh && \
    wget -O /tini https://github.com/krallin/tini/releases/download/v0.18.0/tini-static && \
    chmod +x /tini && \

    echo "---> Add PHP repositories" && \
    wget -O /etc/apk/keys/php-alpine.rsa.pub https://packages.whatwedo.ch/php-alpine.rsa.pub && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.12/community" >> /etc/apk/repositories && \
    echo "https://packages.whatwedo.ch/php-alpine/v3.12/php-8.0" >> /etc/apk/repositories && \

    echo "---> Install PHP and Extensions" && \
    apk add --update \
    php8 \
    php8-bcmath \
    php8-curl \
    php8-phpdbg \
    php8-exif \
    php8-fpm \
    php8-gd \
    php8-iconv \
    php8-imagick \
    php8-intl \
    # php8-json \
    php8-mbstring \
    php8-memcached \
    php8-opcache \
    php8-openssl \
    php8-pcntl \
    php8-pdo_pgsql \
    php8-pgsql \
    php8-phar \
    php8-posix \
    php8-redis \
    php8-sodium \
    php8-xdebug \
    php8-xml \
    php8-xmlreader \
    php8-xsl \
    php8-zip \
    php8-zlib && \

    echo "---> Configuring PHP" && \
    sudo ln -s /usr/bin/php8 /usr/bin/php && \
    sudo ln -s /usr/bin/php-cgi7 /usr/bin/php-cgi && \
    sudo ln -s /usr/sbin/php-fpm7 /usr/sbin/php-fpm && \
    sed -i "/user = .*/c\user = root" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/^group = .*/c\group = root" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/listen.owner = .*/c\listen.owner = root" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/listen.group = .*/c\listen.group = root" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/listen = .*/c\listen = [::]:9000" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/;clear_env = .*/c\clear_env = no" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /etc/php8/php-fpm.d/www.conf && \
    sed -i "/pid = .*/c\;pid = /run/php/php8.0-fpm.pid" /etc/php8/php-fpm.conf && \
    sed -i "/;daemonize = .*/c\daemonize = yes" /etc/php8/php-fpm.conf && \
    sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /etc/php8/php-fpm.conf && \
    sed -i "/post_max_size = .*/c\post_max_size = 1000M" /etc/php8/php.ini && \
    sed -i "/upload_max_filesize = .*/c\upload_max_filesize = 1000M" /etc/php8/php.ini && \
    sed -i "/memory_limit = .*/c\memory_limit = 1024M" /etc/php8/php.ini && \
    sed -i "/zend_extension=xdebug/c\;zend_extension=xdebug" /etc/php8/conf.d/00_xdebug.ini && \

    echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \

    echo "---> Installing PHPUnit" && \
    wget https://phar.phpunit.de/phpunit-9.5.5.phar && \
    chmod +x phpunit-9.5.5.phar && \
    mv phpunit-9.5.5.phar /usr/local/bin/phpunit && \

    echo "---> Installing Supercronic" && \
    curl -fsSLO "https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64" && \
    echo "048b95b48b708983effb2e5c935a1ef8483d9e3e  supercronic-linux-amd64" | sha1sum -c - && \
    chmod +x "supercronic-linux-amd64" && \
    mv "supercronic-linux-amd64" "/usr/local/bin/supercronic-linux-amd64" && \
    ln -s "/usr/local/bin/supercronic-linux-amd64" /usr/local/bin/supercronic && \

    echo "---> Cleaning up" && \
    apk del --purge ca-certificates curl && \
    rm -rf /tmp/* /var/cache/apk/*

# Set the application directory
WORKDIR "/var/www"

# Set our path
ENV PATH=/root/.composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Run init.sh
ENTRYPOINT ["/tini", "--", "/root/init.sh"]

# Allow the container to also be used as a non daemon and single base image
CMD ["/bin/bash"]
