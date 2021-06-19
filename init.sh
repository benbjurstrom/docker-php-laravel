#!/bin/sh

##
# exit if a command returns a non-zero exit code, exit if any unbound variables
#
set -e -u

# Set PHP memory limit value.
sudo sed -i "/memory_limit = .*/c\memory_limit = $PHP_MEMORY_LIMIT" /etc/php8/php.ini


# OPCache extreme mode.
if [[ $OPCACHE_MODE == "extreme" ]]; then
    # enable extreme caching for OPCache.
    echo "opcache.enable=1" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
    echo "opcache.memory_consumption=512" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
    echo "opcache.interned_strings_buffer=128" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
    echo "opcache.max_accelerated_files=32531" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
    echo "opcache.validate_timestamps=0" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
    echo "opcache.save_comments=1" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
    echo "opcache.fast_shutdown=0" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
fi

# OPCache disabled mode.
if [[ $OPCACHE_MODE == "disabled" ]]; then
    # disable extension.
    sudo sed -i "/zend_extension=opcache/c\;zend_extension=opcache" /etc/php8/conf.d/00_opcache.ini
    # set enabled as zero, case extension still gets loaded (by other extension).
    echo "opcache.enable=0" | sudo tee -a /etc/php8/conf.d/00_opcache.ini > /dev/null
fi

if [[ $XDEBUG_ENABLED == true ]]; then
    # enable xdebug extension
    sudo sed -i "/;zend_extension=xdebug/c\zend_extension=xdebug" /etc/php8/conf.d/00_xdebug.ini

    # enable xdebug remote config
    echo "[xdebug]" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo "xdebug.remote_enable=1" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo "xdebug.remote_host=`/sbin/ip route|awk '/default/ { print $3 }'`" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo "xdebug.remote_port=9000" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo "xdebug.scream=0" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo "xdebug.cli_color=1" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo "xdebug.show_local_vars=1" | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null
    echo 'xdebug.idekey = "prezet"' | sudo tee -a /etc/php8/conf.d/00_xdebug.ini > /dev/null

fi

##
# Run php-fpm
#
if [ "$CONTAINER_ROLE" = "app" ]; then
	php-fpm -F -R
fi

##
# Run a laravel queue worker
#
if [ "$CONTAINER_ROLE" = "queue" ]; then
		php /var/www/artisan queue:work $QUEUE_CONNECTION
fi

##
# Configure a cronjob to a run a laravel scheduler heartbeat every five minutes
#
if [ "$CONTAINER_ROLE" = "scheduler" ]; then
	 supercronic /root/crontab
fi

echo "Variable CONTAINER_ROLE must be one of app, queue, websocket, or scheduler"
exit 1
