#!/bin/bash
set -e

MYSQL_USER="$(cat /run/secrets/db_user)"
MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
MYSQL_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

if [ ! -d "/var/lib/mysql/mysql" ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

mysqld_safe --datadir=/var/lib/mysql &

while ! mysqladmin ping --silent; do
	sleep 1
done

if mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
	MYSQL_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
else
	MYSQL_CMD="mysql"
	$MYSQL_CMD -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
	MYSQL_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
fi

$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
$MYSQL_CMD -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
$MYSQL_CMD -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
$MYSQL_CMD -e "FLUSH PRIVILEGES;"

mysqladmin -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown

exec mysqld --user=mysql --datadir=/var/lib/mysql
