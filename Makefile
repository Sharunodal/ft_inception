# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: arissane <arissane@student.hive.fi>        +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/06/13 10:23:34 by arissane          #+#    #+#              #
#    Updated: 2025/06/13 10:38:43 by arissane         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
ENV = srcs/.env
SECRETS = secrets/
MARIADB_VOLUME = /home/$(USER)/data/mariadb
WORDPRESS_VOLUME = /home/$(USER)/data/wordpress

all: up

## Check if Docker is running
check-docker:
	@docker info > /dev/null 2>&1 || (echo "Docker is not running!" && exit 1)

## Check required secret files exist
check-secrets:
	@if [ ! -f $(SECRETS)/db_password.txt ] || \
	    [ ! -f $(SECRETS)/db_root_password.txt ] || \
	    [ ! -f $(SECRETS)/wp_admin_password.txt ] || \
	    [ ! -f $(SECRETS)/wp_user_password.txt ]; then \
	    echo "Missing one or more required secret files in $(SECRETS)/"; \
	    exit 1; \
	fi

## Create required volume mountpoints
create-dirs:
	@mkdir -p $(MARIADB_VOLUME)
	@mkdir -p $(WORDPRESS_VOLUME)

## Start project (build and run)
up: check-docker check-secrets create-dirs
	@echo "Starting $(NAME)..."
	$(COMPOSE) --env-file $(ENV) up -d --build

## Stop project
down:
	@echo "Stopping $(NAME)..."
	$(COMPOSE) down

## Restart project
restart: down up

## Build images only
build:
	@echo "Building Docker images..."
	$(COMPOSE) build

## Stop and remove containers (keep volumes)
clean:
	@echo "Cleaning up containers..."
	$(COMPOSE) down

## Remove everything: containers, volumes, images, orphans
fclean: clean
	@echo "Removing all volumes, images, and orphans..."
	$(COMPOSE) down -v --rmi all --remove-orphans
	@docker system prune -f

## Rebuild everything from scratch
re: fclean all

.PHONY: all up down restart build clean fclean re check-docker check-secrets create-dirs
