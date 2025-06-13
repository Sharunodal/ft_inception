#!/bin/bash
set -e

cd /var/www/html

# Configure PHP-FPM only once
if [ ! -f /etc/.firstrun ]; then
    echo "Configuring PHP-FPM..."

    sed -i 's/listen = .*/listen = 9000/' /etc/php/*/fpm/pool.d/www.conf
    sed -i 's/;clear_env = no/clear_env = no/' /etc/php/*/fpm/pool.d/www.conf

    echo "php_admin_value[memory_limit] = 512M" >> /etc/php/*/fpm/pool.d/www.conf
    touch /etc/.firstrun
fi

# Wait for MariaDB
echo "Waiting for MariaDB..."
timeout=210
counter=0
until mysqladmin ping --protocol=tcp --host=mariadb -u "$MYSQL_USER" --password="$MYSQL_PASSWORD" &>/dev/null; do
    counter=$((counter + 1))
    if [ $counter -gt $timeout ]; then
        echo "Timed out waiting for MariaDB"
        exit 1
    fi
    if [ $((counter % 5)) -eq 0 ]; then
        echo "Still waiting for MariaDB... ($counter/$timeout seconds)"
    fi
    sleep 1
done
echo "MariaDB is up!"

# Initialize volume
if [ ! -f .firstmount ]; then
    echo "Installing WordPress..."

    curl -O https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz --strip-components=1
    rm latest.tar.gz

    if [ ! -f wp-config.php ]; then
        cp wp-config-sample.php wp-config.php
        sed -i "s/database_name_here/$MYSQL_DATABASE/" wp-config.php
        sed -i "s/username_here/$MYSQL_USER/" wp-config.php
        sed -i "s/password_here/$MYSQL_PASSWORD/" wp-config.php
        sed -i "s/localhost/mariadb/" wp-config.php
        sed -i "/That's all, stop editing/i define('FS_METHOD', 'direct');" wp-config.php

        curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php
    fi

    wp core install --allow-root \
        --skip-email \
        --url="$DOMAIN_NAME" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL"

    if [ -n "$WORDPRESS_USER" ] && [ -n "$WORDPRESS_PASSWORD" ] && [ -n "$WORDPRESS_EMAIL" ]; then
        wp user create "$WORDPRESS_USER" "$WORDPRESS_EMAIL" --role=author --user_pass="$WORDPRESS_PASSWORD" --allow-root
    fi

    chown -R www-data:www-data /var/www/html
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;

    touch .firstmount
else
    echo "WordPress already initialized."
fi

echo "Starting PHP-FPM..."
exec php-fpm -F
