# USER DOCUMENTATION

## Overview

This project deploys a WordPress website with Docker

Services included

NGINX HTTPS reverse proxy  
WordPress PHP-FPM  
MariaDB database  

All services run inside containers and communicate by a Docker network

## Requirements

Docker  
Docker Compose  
make  

installation need

docker --version  
docker-compose --version  
make --version  

## Installation

Create secrets fisrt or it will not work

mkdir secrets

echo wpuser > secrets/db_user.txt  
echo nicolsan > secrets/wp_admin_user.txt  
echo user > secrets/wp_user.txt  
echo rootpass > secrets/db_root_password.txt  
echo wppassword > secrets/db_password.txt  
echo adminpass > secrets/wp_admin_password.txt  
echo userpass > secrets/wp_user_password.txt  

## Start the project

make

## Stop the project

make down

## Remove containers and volumes

make clean

## Rebuild the project

make re

## Check services

docker ps

Expected containers:			nginx	wordpress	mariadb  

## Access the website

Public:

https://nicolsan.42.fr

Admin:

https://nicolsan.42.fr/wp-admin

Administrator credentials:		secrets/wp_admin_user.txt	secrets/wp_admin_password.txt  

User credentials:				secrets/wp_user.txt  		secrets/wp_user_password.txt  

## Verify the database

docker exec mariadb sh -c 'mysql -uroot -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'

Expected database:				wordpress