FROM debian:12.11.0

RUN apk update && apk add --no-cache mariadb mariadb-client

COPY tools/mariadb-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb-entrypoint.sh

RUN mkdir -p /run/secrets

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint.sh"]
