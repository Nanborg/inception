#!/bin/bash
set -e

MYSQL_USER="$(cat /run/secrets/db_user)"
MYSQL_PASSWORD="$(cat /run/secrets/db_password)"

WP_ADMIN_USER="$(cat /run/secrets/wp_admin_user)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_ADMIN_EMAIL="$(cat /run/secrets/wp_admin_email)"

WP_USER="$(cat /run/secrets/wp_user)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"
WP_USER_EMAIL="$(cat /run/secrets/wp_user_email)"

cd /var/www/html

if [ ! -f wp-config.php ]; then
	cp wp-config-sample.php wp-config.php
	sed -i "s/database_name_here/$MYSQL_DATABASE/" wp-config.php
	sed -i "s/username_here/$MYSQL_USER/" wp-config.php
	sed -i "s/password_here/$MYSQL_PASSWORD/" wp-config.php
	sed -i "s/localhost/mariadb/" wp-config.php
fi

until mysql -hmariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $MYSQL_DATABASE;" >/dev/null 2>&1; do
	sleep 2
done

if ! wp core is-installed --allow-root --path=/var/www/html >/dev/null 2>&1; then
	wp core install \
		--allow-root \
		--path=/var/www/html \
		--url="$DOMAIN_NAME" \
		--title="Inception" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email
fi

if ! wp user get "$WP_USER" --field=ID --allow-root --path=/var/www/html >/dev/null 2>&1; then
	wp user create "$WP_USER" "$WP_USER_EMAIL" \
		--user_pass="$WP_USER_PASSWORD" \
		--role=author \
		--allow-root \
		--path=/var/www/html
fi

exec php-fpm7.4 -F

