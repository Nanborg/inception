COMPOSE = docker-compose -f srcs/docker-compose/docker-compose.yml

all:
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

re: clean all