#!/usr/bin/env bash
set -u

# =========================
# Inception evaluator helper
# =========================
# Usage:
#   chmod +x inception_check.sh
#   ./inception_check.sh
#
# Optional env vars:
#   LOGIN=ilhi61 DOMAIN=ilhi61.42.fr WP_ADMIN_USER=marvin ./inception_check.sh
#
# Notes:
# - Run from the root of the repository.
# - This script starts from Docker cleanup/tests only.
# - Some subject points cannot be fully automated: they are marked MANUAL.
# - The script does not grade; it reports what looks correct/problematic.

#LOGIN="${LOGIN:-$(whoami)}"
#DOMAIN="${DOMAIN:-${LOGIN}.42.fr}"
#PROJECT_DIR="$(pwd)"

HOST_USER="${HOST_USER:-$(whoami)}"
LOGIN="${LOGIN:-nicolsan}"
DOMAIN="${DOMAIN:-${LOGIN}.42.fr}"
PROJECT_DIR="$(pwd)"

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
BLU='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
MANUAL_COUNT=0

failures=()
warnings=()
manuals=()

step() {
	printf "\n${BLU}==> %s${NC}\n" "$1"
}

ok() {
	printf "${GRN}[OK]${NC} %s\n" "$1"
	((PASS_COUNT++))
}

fail() {
	printf "${RED}[FAIL]${NC} %s\n" "$1"
	((FAIL_COUNT++))
	failures+=("$1")
}

warn() {
	printf "${YLW}[WARN]${NC} %s\n" "$1"
	((WARN_COUNT++))
	warnings+=("$1")
}

manual() {
	printf "${BLU}[MANUAL]${NC} %s\n" "$1"
	((MANUAL_COUNT++))
	manuals+=("$1")
}

has_cmd() {
	command -v "$1" >/dev/null 2>&1
}

file_exists_any() {
	local found=1
	for f in "$@"; do
		if [ -f "$f" ]; then
			found=0
			break
		fi
	done
	return $found
}

get_compose_file() {
	if [ -f "./docker-compose.yml" ]; then
		echo "./docker-compose.yml"
		return
	fi
	if [ -f "./srcs/docker-compose.yml" ]; then
		echo "./srcs/docker-compose.yml"
		return
	fi
	echo ""
}

COMPOSE_FILE="$(get_compose_file)"

compose_cmd() {
	if docker compose version >/dev/null 2>&1; then
		docker compose -f "$COMPOSE_FILE" "$@"
	elif has_cmd docker-compose; then
		docker-compose -f "$COMPOSE_FILE" "$@"
	else
		return 127
	fi
}

cleanup_docker() {
	step "1. Nettoyage Docker"
	if ! has_cmd docker; then
		fail "docker n'est pas installé"
		return
	fi

	# Nettoyage demandé par le sujet
	docker stop $(docker ps -qa) >/dev/null 2>&1 || true
	docker rm $(docker ps -qa) >/dev/null 2>&1 || true
	docker rmi -f $(docker images -qa) >/dev/null 2>&1 || true
	docker volume rm $(docker volume ls -q) >/dev/null 2>&1 || true
	docker network rm $(docker network ls -q) >/dev/null 2>&1 || true

	ok "nettoyage Docker terminé"
}

check_required_files() {
	step "2. Présence des fichiers utiles au run"

	if [ -d "./srcs" ]; then
		ok "dossier srcs présent"
	else
		fail "dossier srcs absent à la racine"
	fi

	if [ -f "./Makefile" ]; then
		ok "Makefile présent à la racine"
	else
		fail "Makefile absent à la racine"
	fi

	if [ -n "$COMPOSE_FILE" ]; then
		ok "docker-compose trouvé: $COMPOSE_FILE"
	else
		fail "docker-compose.yml introuvable (racine ou srcs/)"
	fi

	if [ -f "./README.md" ]; then
		ok "README.md présent"
	else
		warn "README.md absent"
	fi

	if [ -f "./USER_DOC.md" ] && [ -s "./USER_DOC.md" ]; then
		ok "USER_DOC.md présent et non vide"
	else
		warn "USER_DOC.md absent ou vide"
	fi

	if [ -f "./DEV_DOC.md" ] && [ -s "./DEV_DOC.md" ]; then
		ok "DEV_DOC.md présent et non vide"
	else
		warn "DEV_DOC.md absent ou vide"
	fi
}

check_compose_static_rules() {
	step "3. Vérifications statiques compose/scripts"

	if [ -z "$COMPOSE_FILE" ]; then
		fail "impossible de vérifier compose: fichier absent"
		return
	fi

	if grep -RInE 'network:[[:space:]]*host' "$COMPOSE_FILE" ./srcs ./Makefile >/dev/null 2>&1; then
		fail "présence interdite de 'network: host'"
	else
		ok "pas de 'network: host'"
	fi

	if grep -RInE '(^|[[:space:]])links:' "$COMPOSE_FILE" ./srcs ./Makefile >/dev/null 2>&1; then
		fail "présence interdite de 'links:'"
	else
		ok "pas de 'links:'"
	fi

	if grep -RInE '(^|[[:space:]])networks:' "$COMPOSE_FILE" >/dev/null 2>&1; then
		ok "'networks:' présent dans docker-compose"
	else
		fail "'networks:' absent dans docker-compose"
	fi

	if grep -RIn --exclude='inception_check.sh' -- '--link' srcs Makefile >/dev/null 2>&1; then
		fail "présence interdite de '--link' dans le repo"
	else
		ok "pas de '--link' dans le repo"
	fi
}

check_dockerfiles() {
	step "4. Vérifications Dockerfiles"

	mapfile -t dockerfiles < <(find . -type f \( -iname 'Dockerfile' -o -iname 'Dockerfile.*' \) | sort)

	if [ "${#dockerfiles[@]}" -eq 0 ]; then
		fail "aucun Dockerfile trouvé"
		return
	fi

	ok "${#dockerfiles[@]} Dockerfile(s) trouvé(s)"

	local bad_bg=0
	local bad_shell=0
	local bad_loop=0
	local bad_from=0

	for df in "${dockerfiles[@]}"; do
		if [ ! -s "$df" ]; then
			fail "Dockerfile vide: $df"
			continue
		fi

		if grep -InE 'tail -f|sleep infinity|tail -f /dev/null|tail -f /dev/random' "$df" >/dev/null 2>&1; then
			fail "commande interdite trouvée dans $df"
			bad_bg=1
		fi

		if grep -InE 'ENTRYPOINT|CMD' "$df" | grep -E 'nginx[[:space:]]*&|php-fpm[[:space:]]*&|mariadbd?[[:space:]]*&|bash[[:space:]]*$|sh[[:space:]]*$' >/dev/null 2>&1; then
			fail "processus en arrière-plan ou shell lancé incorrectement dans $df"
			bad_shell=1
		fi

		if grep -InE '^FROM[[:space:]]+(alpine|debian):' "$df" >/dev/null 2>&1; then
			ok "base Alpine/Debian détectée dans $df"
		elif grep -InE '^FROM[[:space:]]+' "$df" >/dev/null 2>&1; then
			warn "base non standard à vérifier manuellement dans $df"
			bad_from=1
		else
			fail "aucune ligne FROM valide dans $df"
			bad_from=1
		fi
	done

	if grep -RInE --exclude='inception_check.sh' 'while true|for[[:space:]]*\(\(;;\)\)|sleep infinity|tail -f /dev/null|tail -f /dev/random' srcs >/dev/null 2>&1; then
		fail "boucle infinie/commande interdite trouvée dans le repo"
		bad_loop=1
	else
		ok "pas de boucle infinie/commande interdite détectée"
	fi

	if [ "$bad_from" -eq 1 ]; then
		manual "vérifier que la version utilisée est bien l'avant-dernière stable Alpine/Debian"
	fi
}

run_make() {
	step "5. Lancement du projet"

	if [ ! -f "./Makefile" ]; then
		fail "Makefile absent, impossible de lancer make"
		return
	fi

	if make >/tmp/inception_make.log 2>&1; then
		ok "make a réussi"
	else
		fail "make a échoué (voir /tmp/inception_make.log)"
		return
	fi

	if compose_cmd ps >/tmp/inception_ps.log 2>&1; then
		ok "docker compose ps fonctionne"
		cat /tmp/inception_ps.log
	else
		fail "docker compose ps a échoué"
	fi
}

check_containers_and_networks() {
	step "6. Conteneurs et réseau"

	local ps_out
	ps_out="$(docker ps --format '{{.Names}}|{{.Image}}|{{.Status}}')"

	if [ -n "$ps_out" ]; then
		ok "au moins un conteneur est lancé"
		printf "%s\n" "$ps_out"
	else
		fail "aucun conteneur lancé"
	fi

	local networks
	networks="$(docker network ls --format '{{.Name}}')"
	if [ -n "$networks" ]; then
		ok "au moins un réseau Docker existe"
		printf "%s\n" "$networks"
	else
		fail "aucun réseau Docker visible"
	fi
}

check_service_names_and_images() {
	step "7. Services/images"
	# Vérifier correspondance service ↔ image
mismatch=0

docker compose -f srcs/docker-compose.yml config | \
awk '/services:/,/networks:/' | \
grep 'image:' | while read -r line; do
    image=$(echo "$line" | awk '{print $2}')
    service=$(echo "$image" | sed 's/^srcs-//')
    
    if ! echo "$image" | grep -q "$service"; then
        echo "[FAIL] image '$image' ne correspond pas au service '$service'"
        mismatch=1
    fi
done

if [ "$mismatch" -eq 0 ]; then
    ok "noms des images cohérents avec les services"
else
    fail "incohérence entre noms de services et images"
fi
	# Vérifier images locales
	if docker images --format '{{.Repository}}' | grep -vE '^(srcs-|<none>)' | grep -q .; then
    	warn "images potentiellement externes détectées"
	else
    	ok "images locales cohérentes"
	fi

	if ! compose_cmd config >/tmp/inception_compose_config.txt 2>/dev/null; then
		warn "impossible de lire la config compose résolue"
		return
	fi

	ok "config compose résolue générée"

	if grep -n '^services:' /tmp/inception_compose_config.txt >/dev/null 2>&1; then
		ok "section services détectée"
	else
		fail "section services absente dans compose config"
	fi

	manual "vérifier que le nom des images correspond bien au nom des services"
	
}

check_ports_http_https() {
	step "8. HTTP / HTTPS / TLS"
	# Vérifier contenu HTML réel
	if curl -k https://${DOMAIN} | grep -qi '<title>'; then
    	ok "contenu HTML valide détecté"
	else
    	warn "contenu HTML non détecté"
	fi
	if ! has_cmd curl; then
		fail "curl absent"
		return
	fi

	local http_code https_code
	http_code="$(curl -s -o /tmp/inception_http.out -w '%{http_code}' --max-time 10 "http://${DOMAIN}" || true)"

	https_code=""
	for i in 1 2 3 4 5 6; do
		https_code="$(curl -k -s -o /tmp/inception_https.out -w '%{http_code}' --max-time 10 "https://${DOMAIN}" || true)"
		[ "$https_code" = "200" ] || [ "$https_code" = "301" ] || [ "$https_code" = "302" ] && break
		sleep 5
	done
	if [ "$https_code" = "200" ] || [ "$https_code" = "301" ] || [ "$https_code" = "302" ]; then
		ok "HTTPS répond sur https://${DOMAIN} (code $https_code)"
	else
		fail "HTTPS ne répond pas correctement sur https://${DOMAIN} (code ${https_code:-N/A})"
	fi

	# Sujet: ne pas pouvoir accéder en http://login.42.fr
	if [ "$http_code" = "000" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
		ok "HTTP non accessible directement ou redirigé (code $http_code)"
	else
		fail "HTTP semble accessible sur http://${DOMAIN} (code $http_code)"
	fi

	if has_cmd openssl; then
		local tls12 tls13
		tls12=0
		tls13=0
		openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" -tls1_2 </dev/null >/tmp/inception_tls12.txt 2>/dev/null && tls12=1 || true
		openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" -tls1_3 </dev/null >/tmp/inception_tls13.txt 2>/dev/null && tls13=1 || true

		if [ "$tls12" -eq 1 ] || [ "$tls13" -eq 1 ]; then
			ok "TLS 1.2 ou 1.3 détecté"
		else
			fail "impossible de valider TLS 1.2/1.3"
		fi
	else
		warn "openssl absent, test TLS non exécuté"
	fi
}

check_wordpress_front() {
	step "9. WordPress front"

	if ! has_cmd curl; then
		fail "curl absent"
		return
	fi

	local body
	body="$(cat /tmp/inception_https.out 2>/dev/null || true)"

	if echo "$body" | grep -qiE 'wordpress'; then
		ok "contenu WordPress probable détecté"
	else
		warn "contenu WordPress non détecté automatiquement"
	fi

	if echo "$body" | grep -qiE 'action="install\.php"|<title>WordPress › Installation</title>|<title>Installation</title>'; then
    fail "page d'installation WordPress détectée"
	else
    	ok "pas de page d'installation WordPress détectée"
	fi

	manual "ouvrir le site dans un navigateur et vérifier visuellement le WordPress configuré"
}

check_wordpress_container() {
	step "10. WordPress / php-fpm / volume"
	# Vérifier php-fpm actif
	if docker exec srcs-wordpress-1 pgrep php-fpm >/dev/null 2>&1; then
    	ok "php-fpm actif"
	else
    	fail "php-fpm non actif"
	fi

	local wp_dockerfile
	wp_dockerfile="$(find . -type f \( -path '*wordpress*Dockerfile*' -o -path '*wp*Dockerfile*' \) | head -n 1 || true)"

	if [ -n "$wp_dockerfile" ]; then
		ok "Dockerfile WordPress trouvé: $wp_dockerfile"
		if grep -qi 'nginx' "$wp_dockerfile"; then
			fail "NGINX trouvé dans le Dockerfile WordPress"
		else
			ok "pas de NGINX dans le Dockerfile WordPress"
		fi
	else
		warn "Dockerfile WordPress non trouvé automatiquement"
	fi

	local wp_container
	wp_container="$(docker ps --format '{{.Names}}' | grep -Ei 'wordpress|wp' | head -n 1 || true)"
	if [ -n "$wp_container" ]; then
		ok "conteneur WordPress probable lancé: $wp_container"
	else
		warn "conteneur WordPress non identifié automatiquement"
	fi

	local vols
	vols="$(docker volume ls --format '{{.Name}}')"
	if [ -n "$vols" ]; then
		ok "des volumes Docker existent"
		printf "%s\n" "$vols"

		local found_home=0
		while read -r v; do
			[ -z "$v" ] && continue
			if docker volume inspect "$v" 2>/dev/null | grep -q "/home/.*/data/"; then
				ok "volume $v monte vers /home/${LOGIN}/data/"
				found_home=1
			fi
		done <<< "$vols"

		if [ "$found_home" -eq 0 ]; then
			fail "aucun volume ne pointe vers /home/${LOGIN}/data/"
		fi
	else
		fail "aucun volume Docker trouvé"
	fi

	manual "se connecter à WordPress, poster un commentaire, modifier une page, vérifier la persistance"
	manual "vérifier que l'utilisateur admin ne contient pas 'admin' ou 'Admin'"
}

check_mariadb_container() {
	step "11. MariaDB / volume / base non vide"
	# Vérifier que la DB WordPress contient des tables
	if docker exec srcs-mariadb-1 sh -c "mariadb -u wpuser -pwppassword -e 'USE wordpress; SHOW TABLES;'" 2>/dev/null | grep -q wp_; then
    	ok "DB WordPress non vide"
	else
    	fail "DB WordPress vide ou inaccessible"
	fi
	local db_dockerfile
	db_dockerfile="$(find . -type f \( -path '*mariadb*Dockerfile*' -o -path '*mysql*Dockerfile*' \) | head -n 1 || true)"

	if [ -n "$db_dockerfile" ]; then
		ok "Dockerfile MariaDB trouvé: $db_dockerfile"
		if grep -qi 'nginx' "$db_dockerfile"; then
			fail "NGINX trouvé dans le Dockerfile MariaDB"
		else
			ok "pas de NGINX dans le Dockerfile MariaDB"
		fi
	else
		warn "Dockerfile MariaDB non trouvé automatiquement"
	fi

	local db_container
	db_container="$(docker ps --format '{{.Names}}' | grep -Ei 'mariadb|mysql' | head -n 1 || true)"
	if [ -n "$db_container" ]; then
		ok "conteneur MariaDB probable lancé: $db_container"
	else
		fail "conteneur MariaDB non identifié"
		return
	fi

	if docker exec "$db_container" sh -c 'command -v mariadb >/dev/null 2>&1 || command -v mysql >/dev/null 2>&1'; then
		ok "client SQL disponible dans le conteneur DB"
	else
		warn "client SQL absent du conteneur DB"
	fi

	manual "demander à l'étudiant la commande de connexion DB"
	
}

check_nginx_container() {
	step "12. NGINX"

	local nginx_dockerfile
	nginx_dockerfile="$(find . -type f -path '*nginx*Dockerfile*' | head -n 1 || true)"

	if [ -n "$nginx_dockerfile" ]; then
		ok "Dockerfile NGINX trouvé: $nginx_dockerfile"
	else
		warn "Dockerfile NGINX non trouvé automatiquement"
	fi

	local nginx_container
	nginx_container="$(docker ps --format '{{.Names}}' | grep -Ei 'nginx' | head -n 1 || true)"
	if [ -n "$nginx_container" ]; then
		ok "conteneur NGINX probable lancé: $nginx_container"
	else
		warn "conteneur NGINX non identifié automatiquement"
	fi

	if ss -ltn 2>/dev/null | grep -q ':443 '; then
		ok "quelque chose écoute sur le port 443"
	else
		fail "rien n'écoute sur le port 443"
	fi
}

check_bonus() {
	step "13. Bonus (détection simple)"

	local names
	names="$(docker ps --format '{{.Names}}' | tr '[:upper:]' '[:lower:]')"

	if echo "$names" | grep -q 'redis'; then
		ok "bonus Redis détecté"
		local redis_c
		redis_c="$(docker ps --format '{{.Names}}' | grep -Ei 'redis' | head -n 1 || true)"
		if [ -n "$redis_c" ] && docker exec "$redis_c" redis-cli ping >/tmp/inception_redis.txt 2>/dev/null; then
			if grep -q 'PONG' /tmp/inception_redis.txt; then
				ok "Redis répond à PING"
			else
				warn "Redis détecté mais PING non concluant"
			fi
		else
			warn "Redis détecté mais test PING impossible"
		fi
	else
		warn "bonus Redis non détecté"
	fi

	if echo "$names" | grep -q 'ftp'; then
		ok "bonus FTP détecté"
	else
		warn "bonus FTP non détecté"
	fi

	if echo "$names" | grep -q 'adminer'; then
		ok "bonus Adminer détecté"
	else
		warn "bonus Adminer non détecté"
	fi

	manual "vérifier manuellement le site statique bonus"
	manual "vérifier et justifier le service bonus libre"
}

summary() {
	step "Résumé"

	printf "${GRN}OK:${NC} %d\n" "$PASS_COUNT"
	printf "${RED}FAIL:${NC} %d\n" "$FAIL_COUNT"
	printf "${YLW}WARN:${NC} %d\n" "$WARN_COUNT"
	printf "${BLU}MANUAL:${NC} %d\n" "$MANUAL_COUNT"

	if [ "${#failures[@]}" -gt 0 ]; then
		printf "\n${RED}Points en échec:${NC}\n"
		printf ' - %s\n' "${failures[@]}"
	fi

	if [ "${#warnings[@]}" -gt 0 ]; then
		printf "\n${YLW}Points à vérifier:${NC}\n"
		printf ' - %s\n' "${warnings[@]}"
	fi

	if [ "${#manuals[@]}" -gt 0 ]; then
		printf "\n${BLU}Points manuels:${NC}\n"
		printf ' - %s\n' "${manuals[@]}"
	fi
}

main() {
	check_required_files
	cleanup_docker
	check_compose_static_rules
	check_dockerfiles
	run_make
	check_containers_and_networks
	check_service_names_and_images
	check_ports_http_https
	check_wordpress_front
	check_nginx_container
	check_wordpress_container
	check_mariadb_container
	check_bonus
	summary
}

main