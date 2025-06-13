#!/bin/sh
set -e

# Configure MariaDB to listen on all interfaces (for Docker networking)
if [ ! -f /etc/.firstrun ]; then
  echo "[mysqld]" >> /etc/my.cnf.d/mariadb-server.cnf
  echo "bind-address=0.0.0.0" >> /etc/my.cnf.d/mariadb-server.cnf
  echo "skip-networking=0" >> /etc/my.cnf.d/mariadb-server.cnf
  touch /etc/.firstrun
fi

# First volume mount — initialize DB and create users
if [ ! -f /var/lib/mysql/.firstmount ]; then
  mysql_install_db --datadir=/var/lib/mysql --skip-test-db --user=mysql --auth-root-authentication-method=socket

  # Start MariaDB in background temporarily
  mysqld &
  pid="$!"

  echo "Waiting for MariaDB to be ready..."
  while ! mysqladmin ping --silent; do
    sleep 1
  done

  echo "Setting up initial database and users..."

  # Read secrets securely
  DB_NAME="${MYSQL_DATABASE:-wordpress}"
  DB_USER="${MYSQL_USER:-wpuser}"
  DB_PASS="$(cat /run/secrets/db_password)"
  ROOT_PASS="$(cat /run/secrets/db_root_password)"

  cat <<EOF | mysql -u root --protocol=socket
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$ROOT_PASS';
FLUSH PRIVILEGES;
EOF

  echo "Shutting down temporary MariaDB..."
  mysqladmin shutdown

  touch /var/lib/mysql/.firstmount
fi

# Replace shell with MariaDB to ensure it runs as PID 1
exec mysqld
