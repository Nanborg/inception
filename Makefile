##LOGIN = nicolsan
DATA_PATH ?= $(HOME)/data
COMPOSE = DATA_PATH="$(DATA_PATH)" docker-compose -f srcs/docker-compose.yml

env:
	@{ \
	echo "DATA_PATH=$(DATA_PATH)"; \
	echo "MYSQL_USER=$$(cat secrets/db_user.txt)"; \
	echo "MYSQL_PASSWORD=$$(cat secrets/db_password.txt)"; \
	echo "MYSQL_ROOT_PASSWORD=$$(cat secrets/db_root_password.txt)"; \
	echo "WP_ADMIN_USER=$$(cat secrets/wp_admin_user.txt)"; \
	echo "WP_ADMIN_PASSWORD=$$(cat secrets/wp_admin_password.txt)"; \
	echo "WP_ADMIN_EMAIL=$$(cat secrets/wp_admin_email.txt)"; \
	echo "WP_USER=$$(cat secrets/wp_user.txt)"; \
	echo "WP_USER_PASSWORD=$$(cat secrets/wp_user_password.txt)"; \
	echo "WP_USER_EMAIL=$$(cat secrets/wp_user_email.txt)"; \
	} > srcs/.env

all: env
	mkdir -p $(DATA_PATH)/mariadb
	mkdir -p $(DATA_PATH)/wordpress
	chmod 600 secrets/*.txt
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean: clean
	docker system prune -af
	docker run --rm -v $(DATA_PATH):/data alpine sh -c "rm -rf /data/mariadb /data/wordpress"
	mkdir -p $(DATA_PATH)/mariadb
	mkdir -p $(DATA_PATH)/wordpress

re: fclean all
