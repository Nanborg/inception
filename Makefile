LOGIN = $(shell whoami)
DATA_PATH = /home/$(LOGIN)/data
COMPOSE = DATA_PATH=$(DATA_PATH) docker-compose -f srcs/docker-compose/docker-compose.yml

all:
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
