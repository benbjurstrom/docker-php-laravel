###
# Based on https://github.com/ambientum/ambientum/blob/master/php/7.3/Dockerfile
#
FROM alpine:3.10

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
    unzip && \

    echo "---> Adding /var/www" && \
    mkdir -p /var/www && \
    chmod +x /root/init.sh && \
    wget -O /tini https://github.com/krallin/tini/releases/download/v0.18.0/tini-static && \
    chmod +x /tini && \

    echo "---> Add PHP repositories" && \
    wget -O /etc/apk/keys/php-alpine.rsa.pub https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.10/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.10/community" >> /etc/apk/repositories && \
    echo "https://dl.bintray.com/php-alpine/v3.10/php-7.4" >> /etc/apk/repositories && \

    echo "---> Install PHP and Extensions" && \
    apk add --update \
    php \
    php-bcmath \
    php-curl \
    php-phpdbg \
    php-exif \
    php-fpm \
    php-gd \
    php-iconv \
    php-imagick \
    php-intl \
    php-json \
    php-mbstring \
    php-memcached \
    php-opcache \
    php-openssl \
    php-pcntl \
    php-pdo_pgsql \
    php-pgsql \
    php-phar \
    php-posix \
    php-redis \
    php-sodium \
    php-xdebug \
    php-xml \
    php-xmlreader \
    php-xsl \
    php-zip \
    php-zlib && \

    echo "---> Configuring PHP" && \
    sudo ln -s /usr/bin/php7 /usr/bin/php && \
    sudo ln -s /usr/bin/php-cgi7 /usr/bin/php-cgi && \
    sudo ln -s /usr/sbin/php-fpm7 /usr/sbin/php-fpm && \
    sed -i "/user = .*/c\user = root" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/^group = .*/c\group = root" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/listen.owner = .*/c\listen.owner = root" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/listen.group = .*/c\listen.group = root" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/listen = .*/c\listen = [::]:9000" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/;clear_env = .*/c\clear_env = no" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /etc/php7/php-fpm.d/www.conf && \
    sed -i "/pid = .*/c\;pid = /run/php/php7.1-fpm.pid" /etc/php7/php-fpm.conf && \
    sed -i "/;daemonize = .*/c\daemonize = yes" /etc/php7/php-fpm.conf && \
    sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /etc/php7/php-fpm.conf && \
    sed -i "/post_max_size = .*/c\post_max_size = 1000M" /etc/php7/php.ini && \
    sed -i "/upload_max_filesize = .*/c\upload_max_filesize = 1000M" /etc/php7/php.ini && \
    sed -i "/memory_limit = .*/c\memory_limit = 1024M" /etc/php7/php.ini && \
    sed -i "/zend_extension=xdebug/c\;zend_extension=xdebug" /etc/php7/conf.d/00_xdebug.ini && \

    echo "---> Installing Composer" && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \

    echo "---> Installing PHPUnit" && \
    wget https://phar.phpunit.de/phpunit-8.2.phar && \
    chmod +x phpunit-8.2.phar && \
    mv phpunit-8.2.phar /usr/local/bin/phpunit && \

    echo "---> Installing Supercronic" && \
    curl -fsSLO "https://github.com/aptible/supercronic/releases/download/v0.1.9/supercronic-linux-amd64" && \
    echo "5ddf8ea26b56d4a7ff6faecdd8966610d5cb9d85  supercronic-linux-amd64" | sha1sum -c - && \
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
