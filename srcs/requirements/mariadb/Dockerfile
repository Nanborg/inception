FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server

RUN mkdir -p /var/run/mysqld

COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/init.sh /init.sh

RUN chmod +x /init.sh
RUN chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

CMD ["/init.sh"]
