FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /var/run/nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY ssl/nicolsan.42.fr.crt /etc/nginx/ssl/nicolsan.42.fr.crt
COPY ssl/nicolsan.42.fr.key /etc/nginx/ssl/nicolsan.42.fr.key

CMD ["nginx", "-g", "daemon off;"]