# 1. Vérifier la structure du dépôt

Makefile à la racine
test -f Makefile && echo "OK" || echo "KO"

### Résultat attendu : OK

dossier srcs à la racine
test -d srcs && echo "OK" || echo "KO"

### Résultat attendu : OK

voir rapidement la racine
ls -la

### Résultat attendu : présence de Makefile et srcs


# 2. Nettoyer Docker avant make

docker stop $(docker ps -qa) 2>/dev/null; docker rm $(docker ps -qa) 2>/dev/null; docker rmi -f $(docker images -qa) 2>/dev/null; docker volume rm $(docker volume ls -q) 2>/dev/null; docker network rm $(docker network ls -q) 2>/dev/null

### Résultat attendu : environnement Docker vide

vérifier que tout est vide
docker ps -a
docker images
docker volume ls
docker network ls

### Résultat attendu : plus rien du projet


# 3. Vérifier network_mode: host

grep -Rni 'network_mode: host' srcs 2>/dev/null

### Résultat attendu : aucune sortie


# 4. Vérifier links:

grep -Rni 'links:' srcs 2>/dev/null

### Résultat attendu : aucune sortie


# 5. Vérifier qu’un réseau est bien défini

grep -RniE '^ *networks:' srcs/docker-compose/docker-compose.yml 2>/dev/null

### Résultat attendu : au moins une ligne trouvée


# 6. Vérifier --link

grep -Rni -- '--link' .

### Résultat attendu : aucune sortie


# 7. Vérifier tail -f

grep -Rni 'tail -f' .

### Résultat attendu : aucune sortie


# 8. Vérifier sleep infinity

grep -Rni 'sleep infinity' .

### Résultat attendu : aucune sortie


# 9. Vérifier tail -f /dev/null ou /dev/random

grep -RniE 'tail -f /dev/null|tail -f /dev/random' .

### Résultat attendu : aucune sortie


# 10. Vérifier les boucles infinies

grep -RniE 'while true|while :|for *\(;;\)' .

### Résultat attendu : aucune sortie


# 11. Vérifier les process lancés en arrière-plan

grep -RniE '&[[:space:]]*$' srcs

### Résultat attendu : idéalement aucune sortie suspecte


# 12. Vérifier les ENTRYPOINT et CMD

grep -RniE 'ENTRYPOINT|CMD' srcs

### Résultat attendu : lignes normales, pas de shell vide, pas de faux process bloquant


# 13. Vérifier que les Dockerfiles existent

find srcs -type f -name 'Dockerfile' -exec ls -lh {} \;

### Résultat attendu : Dockerfiles présents pour les services


# 14. Vérifier que les Dockerfiles ne sont pas vides

find srcs -type f -name 'Dockerfile' -exec sh -c 'echo "==== $1 ===="; wc -l "$1"' _ {} \;

### Résultat attendu : plusieurs lignes dans chaque Dockerfile


# 15. Vérifier les images de base (FROM)

grep -Rni '^FROM ' srcs

### Résultat attendu : base cohérente et autorisée


# 16. Lancer le projet

make

### Résultat attendu : build + lancement sans erreur

si besoin voir le Makefile

cat Makefile


# 17. Vérifier les conteneurs

docker ps

### Résultat attendu : NGINX, WordPress, MariaDB actifs


autre variante

docker compose -f srcs/docker-compose/docker-compose.yml ps


# 18. Vérifier les images

docker images

### Résultat attendu : images du projet présentes


# 19. Vérifier les réseaux

docker network ls

### Résultat attendu : réseau du projet visible


inspecter le réseau

docker network inspect docker-compose_inception

### Résultat attendu : les conteneurs du projet sont dans ce réseau


# 20. Vérifier les volumes

docker volume ls

### Résultat attendu : volumes WordPress et MariaDB visibles


inspecter les volumes

docker volume inspect docker-compose_mariadb_data
docker volume inspect docker-compose_wordpress_data


# 21. Vérifier que les volumes pointent vers /home/nicolsan/data

docker volume inspect docker-compose_mariadb_data
docker volume inspect docker-compose_wordpress_data

### Résultat attendu : mountpoints liés aux données persistantes du projet


vérifier le dossier hôte

ls -la /home/nicolsan/data

### Résultat attendu : dossier existant


voir le contenu

find /home/nicolsan/data -maxdepth 3

### Résultat attendu : fichiers/dossiers WordPress et MariaDB


# 22. Vérifier NGINX

voir les conteneurs avec leur nom

docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'


logs NGINX

docker logs nginx

### Résultat attendu : pas d’erreur bloquante


entrer dans le conteneur

docker exec -it nginx sh


tester la config

nginx -t

### Résultat attendu : syntax is ok / test is successful


# 23. Vérifier que HTTP ne fonctionne pas

curl -I --max-time 5 http://nicolsan.42.fr

### Résultat attendu : échec, refus, ou pas d’accès valide en HTTP


# 24. Vérifier que HTTPS fonctionne

curl -k -I --max-time 5 https://nicolsan.42.fr

### Résultat attendu : réponse HTTP valide du site


voir la page

curl -k https://nicolsan.42.fr | head -n 30

### Résultat attendu : HTML du site WordPress


# 25. Vérifier le certificat SSL/TLS

openssl s_client -connect nicolsan.42.fr:443 </dev/null

### Résultat attendu : certificat affiché


tester TLS 1.2

openssl s_client -connect nicolsan.42.fr:443 -tls1_2 </dev/null

### Résultat attendu : connexion possible


tester TLS 1.3

openssl s_client -connect nicolsan.42.fr:443 -tls1_3 </dev/null

### Résultat attendu : connexion possible si configuré


résumé du certificat

echo | openssl s_client -connect nicolsan.42.fr:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates

### Résultat attendu : subject, issuer, dates


# 26. Vérifier que WordPress est déjà installé

curl -k https://nicolsan.42.fr | grep -iE 'install|setup|database'

### Résultat attendu : aucune page d’installation


# 27. Vérifier le conteneur WordPress

logs

docker logs wordpress

### Résultat attendu : pas d’erreur bloquante


entrer dedans

docker exec -it wordpress sh


vérifier php-fpm

ps aux | grep php-fpm

### Résultat attendu : php-fpm actif


vérifier qu’il n’y a pas nginx dedans

which nginx

### Résultat attendu : rien / commande introuvable


vérifier les fichiers WordPress

ls -la /var/www/html

### Résultat attendu : fichiers WordPress présents


vérifier wp-config.php

find / -name wp-config.php 2>/dev/null

### Résultat attendu : fichier trouvé


# 28. Vérifier le conteneur MariaDB

logs

docker logs mariadb

### Résultat attendu : pas d’erreur bloquante


entrer dedans

docker exec -it mariadb sh


vérifier qu’il n’y a pas nginx dedans

which nginx

### Résultat attendu : rien / commande introuvable


# 29. Vérifier root sans mot de passe

Dans le conteneur MariaDB :

mysql -u root

### Résultat attendu : échec


# 30. Vérifier la connexion user DB

Dans le conteneur MariaDB :

mysql -u wpuser -p

### Résultat attendu : demande de mot de passe puis connexion OK


# 31. Vérifier que la base n’est pas vide

Après connexion SQL :

SHOW DATABASES;
USE wordpress;
SHOW TABLES;

### Résultat attendu : tables présentes


test direct en une ligne

docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "SHOW DATABASES;"'
docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "USE wordpress; SHOW TABLES;"'


# 32. Vérifier les ports exposés

docker ps --format 'table {{.Names}}\t{{.Ports}}'

### Résultat attendu : exposition cohérente, surtout 443 côté NGINX


# 33. Vérifier Entrypoint et Cmd réels d’un conteneur

docker inspect nginx | grep -iE 'Entrypoint|Cmd'
docker inspect wordpress | grep -iE 'Entrypoint|Cmd'
docker inspect mariadb | grep -iE 'Entrypoint|Cmd'

### Résultat attendu : process normal


# 34. Vérifier les processus réels dans les conteneurs

docker exec -it nginx sh -c 'ps aux'
docker exec -it wordpress sh -c 'ps aux'
docker exec -it mariadb sh -c 'ps aux'


# 35. Vérifier qu’aucun conteneur ne tourne avec un faux process de blocage

for c in $(docker ps --format '{{.Names}}'); do echo "===== $c ====="; docker exec "$c" sh -c "ps aux | grep -E 'tail -f|sleep infinity|/dev/null|/dev/random'"; done

### Résultat attendu : rien de suspect


# 36. Vérifier les logs de tous les conteneurs

for c in $(docker ps --format '{{.Names}}'); do echo "===== $c ====="; docker logs "$c" 2>&1 | tail -n 50; done

### Résultat attendu : pas d’erreur critique


# 37. Vérifier /etc/hosts si nécessaire

cat /etc/hosts

### Résultat attendu : résolution correcte de nicolsan.42.fr


ajouter l’entrée si besoin

echo "127.0.0.1 nicolsan.42.fr" | sudo tee -a /etc/hosts


# 38. Vérifier la persistance avant reboot

voir le contenu WordPress

docker exec -it wordpress sh -c 'ls -la /var/www/html'


voir les tables DB

docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "USE wordpress; SHOW TABLES;"'


### Résultat attendu : données présentes avant reboot


# 39. Reboot de la VM

sudo reboot


# 40. Après reboot : relancer

cd ~/inception
make


# 41. Après reboot : revérifier

docker ps
docker volume ls
curl -k -I https://nicolsan.42.fr


### Résultat attendu : tout refonctionne


revérifier la DB

docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "USE wordpress; SHOW TABLES;"'

### Résultat attendu : données toujours présentes



##### tous les codes a la suite 

test -f Makefile && echo "OK" || echo "KO"
test -d srcs && echo "OK" || echo "KO"
ls -la
docker stop $(docker ps -qa) 2>/dev/null
docker rm $(docker ps -qa) 2>/dev/null
docker rmi -f $(docker images -qa) 2>/dev/null
docker volume rm $(docker volume ls -q) 2>/dev/null
docker network rm $(docker network ls -q) 2>/dev/null
docker ps -a
docker images
docker volume ls
docker network ls
grep -Rni 'network_mode: host' srcs 2>/dev/null
grep -Rni 'links:' srcs 2>/dev/null
grep -RniE '^ *networks:' srcs/docker-compose/docker-compose.yml 2>/dev/null
grep -Rni -- '--link' .
grep -Rni 'tail -f' .
grep -Rni 'sleep infinity' .
grep -RniE 'tail -f /dev/null|tail -f /dev/random' .
grep -RniE 'while true|while :|for *\(;;\)' .
grep -RniE '&[[:space:]]*$' srcs
grep -RniE 'ENTRYPOINT|CMD' srcs
find srcs -type f -name 'Dockerfile' -exec ls -lh {} \;
find srcs -type f -name 'Dockerfile' -exec sh -c 'echo "==== $1 ===="; wc -l "$1"' _ {} \;
grep -Rni '^FROM ' srcs

make

cat Makefile
docker ps
docker compose -f srcs/docker-compose/docker-compose.yml ps
docker images
docker network ls
docker network inspect docker-compose_inception

docker volume ls
docker volume inspect docker-compose_mariadb_data
docker volume inspect docker-compose_wordpress_data
docker volume inspect docker-compose_mariadb_data
docker volume inspect docker-compose_wordpress_data

ls -la /home/nicolsan/data
find /home/nicolsan/data -maxdepth 3
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
docker logs nginx
docker exec -it nginx sh
nginx -t
curl -I --max-time 5 http://nicolsan.42.fr
curl -k -I --max-time 5 https://nicolsan.42.fr
curl -k https://nicolsan.42.fr | head -n 30

openssl s_client -connect nicolsan.42.fr:443 </dev/null
openssl s_client -connect nicolsan.42.fr:443 -tls1_2 </dev/null
openssl s_client -connect nicolsan.42.fr:443 -tls1_3 </dev/null
echo | openssl s_client -connect nicolsan.42.fr:443 2>/dev/null | openssl x509 -noout -subject -issuer -dates
curl -k https://nicolsan.42.fr | grep -iE 'install|setup|database'

docker logs wordpress
docker exec -it wordpress sh
ps aux | grep php-fpm
which nginx
ls -la /var/www/html
find / -name wp-config.php 2>/dev/null
docker logs mariadb
docker exec -it mariadb sh
which nginx
mysql -u root
mysql -u wpuser -p
SHOW DATABASES;
USE wordpress;
SHOW TABLES;

docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "SHOW DATABASES;"'
docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "USE wordpress; SHOW TABLES;"'
docker ps --format 'table {{.Names}}\t{{.Ports}}'
docker inspect nginx | grep -iE 'Entrypoint|Cmd'
docker inspect wordpress | grep -iE 'Entrypoint|Cmd'
docker inspect mariadb | grep -iE 'Entrypoint|Cmd'
docker exec -it nginx sh -c 'ps aux'
docker exec -it wordpress sh -c 'ps aux'
docker exec -it mariadb sh -c 'ps aux'

for c in $(docker ps --format '{{.Names}}'); do echo "===== $c ====="; docker exec "$c" sh -c "ps aux | grep -E 'tail -f|sleep infinity|/dev/null|/dev/random'"; done
for c in $(docker ps --format '{{.Names}}'); do echo "===== $c ====="; docker logs "$c" 2>&1 | tail -n 50; done
cat /etc/hosts
echo "127.0.0.1 nicolsan.42.fr" | sudo tee -a /etc/hosts
docker exec -it wordpress sh -c 'ls -la /var/www/html'
docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "USE wordpress; SHOW TABLES;"'
sudo reboot
cd ~/inception
make
docker ps
docker volume ls
curl -k -I https://nicolsan.42.fr
docker exec mariadb sh -c 'mysql -uwpuser -p"$(cat /run/secrets/db_password)" -e "USE wordpress; SHOW TABLES;"'


