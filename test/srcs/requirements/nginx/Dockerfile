FROM debian:12.11

# Install Nginx, OpenSSL, and necessary tools
RUN apt-get update && \
    apt-get install -y nginx openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY tools/nginx-entrypoint.sh /usr/local/bin/

# Make it executable
RUN chmod +x /usr/local/bin/nginx-entrypoint.sh && \
    mkdir -p /etc/nginx/ssl /var/www/html

# Ensure nginx runs as foreground process
ENTRYPOINT ["/usr/local/bin/nginx-entrypoint.sh"]
