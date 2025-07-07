#!/bin/sh
set -e

# Load from secrets if present
[ -f /run/secrets/db_password ] && export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
[ -f /run/secrets/db_root_password ] && export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# Check required variables
: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"
: "${MYSQL_ROOT_PASSWORD:?Missing MYSQL_ROOT_PASSWORD}"

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    echo "Starting MariaDB for setup..."
    mysqld_safe --skip-networking &
    pid=$!

    echo "Waiting for MariaDB to be responsive..."
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

    mysqladmin shutdown
    wait $pid
fi

# Allow connections from Docker network
echo "[mysqld]" > /etc/mysql/my.cnf
echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf

echo "Starting MariaDB in safe mode..."
exec mysqld_safe
