FROM debian:12.11

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    less \
    mariadb-client \
    php php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip php-intl php-cli php-soap php-imagick php-bcmath php-exif \
    unzip \
    ghostscript \
    imagemagick \
    sudo \
    wget \
    bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Set working directory
WORKDIR /var/www/html

# Copy entrypoint
COPY tools/wordpress-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh

# Expose PHP-FPM port
EXPOSE 9000

ENTRYPOINT [ "wordpress-entrypoint.sh" ]
