*This project has been created as part of the 42 curriculum by nicolsan.*

# Inception

## Description

This project deploys a WordPress infrastructure using Docker

This project contains three services

NGINX HTTPS web server  
WordPress with PHP-FPM  
MariaDB database

Docker Compose orchestrates the containers.  
Docker volumes provide persistent storage.  
Docker secrets store credentials.

Each is built from its own Dockerfile

## Architecture

HTTPS 443 -> NGINX -> WORDPRESS -> MARIADB

Service communication

nginx -> wordpress  
wordpress -> mariadb

All containers run inside the same Docker network

## Project Structure

inception/

Makefile  
README.md  
USER_DOC.md  
DEV_DOC.md  

secrets/  
    db_password.txt 
    db_root_password.txt 
    db_user.txt 
    wp_admin_password.txt 
    wp_admin_user.txt 
    wp_user.txt 
    wp_user_password.txt

srcs/  
    .env  
    docker-compose/  
        docker-compose.yml  
    
    requirements/

        mariadb/  
            Dockerfile  
            conf/  
                my.cnf  
            tools/  
                init.sh 

        nginx/  
            Dockerfile  
            conf/  
                nginx.conf  
            ssl/  
                nicolsan.42.fr.crt  
                nicolsan.42.fr.key  

		wordpress/  
			Dockerfile  
			conf/  
				www.conf  
			tools/  
				setup.sh  

## Instructions
Create secrets fisrt or it will not work

mkdir secrets

echo wpuser > secrets/db_user.txt  
echo nicolsan > secrets/wp_admin_user.txt  
echo user > secrets/wp_user.txt  
echo rootpass > secrets/db_root_password.txt  
echo wppassword > secrets/db_password.txt  
echo adminpass > secrets/wp_admin_password.txt  
echo userpass > secrets/wp_user_password.txt  


Start the project				make

Stop containers:				make down

Remove containers and volumes:	make clean

Rebuild everything:				make re

Check containers:				docker ps

Expected containers:			nginx  wordpress  mariadb  

## Accessing the Website

Public:

https://nicolsan.42.fr

Admin:

https://nicolsan.42.fr/wp-admin

Credentials are stored in:	secrets/wp_admin_user.txt  secrets/wp_admin_password.txt  

## Definitions and choices 

### Virtual Machines / Docker

Virtual machines run a full OS and need more resources

Docker containers use the host kernel and is faster

### Secrets / Environment Variables

Environment variables can expose senitive info in config files

Docker secrets store credentials securely inside

### Docker Network / Host Network

Docker bridge networks isolate containers ,  internal communication.

Host networking exposes containers directly to the host

### Docker Volumes / Bind Mounts

Bind mounts map host directories directly inside containers

Docker volumes are managed by Docker and are a persistent storage.

I used volumes

/var/lib/mysql  
/var/www/html  

## Resources

docker 1h sur youtube 
https://youtu.be/pg19Z8LL06w?si=awCn0vEJD8S9BgwT

playlist docker lessons de codadmin sur docker
https://www.youtube.com/watch?v=SXB6KJ4u5vg&list=PL8SZiccjllt1jz9DsD4MPYbbiGOR_FYHu

tuto inception complet
https://medium.com/@imyzf/inception-3979046d90a0

tuto inception complet mais de grademe
https://tuto.grademe.fr/inception/

## AI Usage

AI was used to understand documentation also to find the reason of my wrongdoings between me and the turorials, has been sometimes useful , sometimes worse than dragonball evolution the film.

