FROM debian:12.11

# Install necessary packages
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script
COPY tools/mariadb-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb-entrypoint.sh

VOLUME /var/lib/mysql

# Use our custom script as the container's entrypoint
ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint.sh"]
