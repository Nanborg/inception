# DEVELOPER DOCUMENTATION

## Overview

This document describes the infrastructure

Services

NGINX  
WordPress  
MariaDB  

Each service is built from its own Dockerfile

## Environment Setup

Required software

Docker  
Docker Compose  
make  

installation if needed:

docker --version  
docker-compose --version  
make --version  

## Docker Architecture

All services run inside the same Docker network

nginx -> wordpress  
wordpress -> mariadb  

## Docker Compose

File: srcs/docker-compose/docker-compose.yml

Responsibilities:       define services   configure volumes   configure secrets    configure network  

## Containers

### MariaDB

Directory:              srcs/requirements/mariadb

Main files:             Dockerfile      conf/my.cnf     tools/init.sh  

Responsibilities:       initialize database		create WordPress database		create WordPress user  

### WordPress

Directory:              srcs/requirements/wordpress

Main files              Dockerfile		conf/www.conf	tools/setup.sh  

Responsibilities:		configure wp-config.php		install WordPress	create users	start PHP-FPM  

### NGINX

Directory:				srcs/requirements/nginx

Main files				Dockerfile		conf/nginx.conf		ssl certificates  

Acts as HTTPS server and reverse proxy
PHP requests are forwarded to the wordpress container

## Secrets

Credentials are stored using Docker secrets

Example location: secrets/db_root_password

## Volumes

Persistent volumes:		/var/lib/mysql			/var/www/html  

MariaDB data and WordPress files remain available after container restart

## Useful commands

docker ps  
docker logs  
docker exec  

Ex:	docker exec nginx nginx -t