#!/bin/sh
set -e

# ENV vars provided via .env or secrets
: "${MYSQL_DATABASE:?}"
: "${MYSQL_USER:?}"
: "${MYSQL_PASSWORD:?}"
: "${MYSQL_ROOT_PASSWORD:?}"

# Setup once per volume
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mysqld_safe --skip-networking &
    pid="$!"

    echo "Waiting for MariaDB to start..."
    until mysqladmin ping --silent; do
        sleep 1
    done

    echo "Creating database and users..."
    cat <<-EOSQL | mariadb
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;
        FLUSH PRIVILEGES;
EOSQL

    echo "Shutting down setup MariaDB instance..."
    mysqladmin shutdown
    wait "$pid"
fi

echo "Starting MariaDB in safe mode..."
exec mysqld_safe
