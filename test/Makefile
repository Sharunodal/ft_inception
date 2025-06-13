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
COMPOSE = docker-compose -f srcs/docker-compose.yml
ENV = srcs/.env

all: up

up:
	@echo "Starting $(NAME)..."
	$(COMPOSE) --env-file $(ENV) up -d --build

down:
	@echo "Stopping $(NAME)..."
	$(COMPOSE) down

restart: down up

build:
	@echo "Building images..."
	$(COMPOSE) build

clean:
	$(COMPOSE) down

fclean: clean
	$(COMPOSE) down -v --rmi all --remove-orphans
	docker system prune -f

re: fclean all

.PHONY: all up down restart build clean fclean re
