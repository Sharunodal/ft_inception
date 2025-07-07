#!/bin/sh
set -e

CERT_DIR="/etc/nginx/ssl"
NGINX_CONF="/etc/nginx/sites-available/default"
DOMAIN_NAME=${DOMAIN_NAME:-localhost}

if [ ! -f /etc/.firstrun ]; then
    echo "Generating self-signed TLS certificate..."
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/cert.key" \
        -out "$CERT_DIR/cert.crt" \
        -subj "/CN=$DOMAIN_NAME"

    chmod 600 "$CERT_DIR/cert.key"
    chmod 644 "$CERT_DIR/cert.crt"

    echo "Creating NGINX configuration..."
    cat > "$NGINX_CONF" <<EOF
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    ssl_certificate     $CERT_DIR/cert.crt;
    ssl_certificate_key $CERT_DIR/cert.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass wordpress:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

    if [ ! -L /etc/nginx/sites-enabled/default ]; then
        ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    fi

    rm -f /etc/nginx/sites-enabled/default.conf || true

    touch /etc/.firstrun
fi

exec nginx -g "daemon off;"
