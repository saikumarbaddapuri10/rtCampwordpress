#!/bin/bash

# Check if docker-compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then
  # Install docker-compose if not present
  echo "Installing Docker Compose..."
  apt-get update
  apt-get install -y docker-compose
fi

# Check if site name argument was provided
if [ -z "$1" ]; then
  echo "Please provide a site name as an argument."
  exit 1
fi
# Entry in /etc/hosts
site_name="as.xvr.com"
echo "127.0.0.1:8000 as.xvr.com" >> /etc/hosts

#creating required files
mkdir wordpress-docker
cd wordpress-docker
# Creating public and nginx
echo "Creating nginx configuration file"
mkdir public nginx
cd nginx
cat > default.conf << EOF
events {}
http{
    server {
        listen 80;
        server_name $host;
        root /usr/share/nginx/html;
        index  index.php index.html index.html;

        location / {
            try_files $uri $uri/ /index.php?$is_args$args;
        }

        location ~ \.php$ {
            # try_files $uri =404;
            # fastcgi_pass unix:/run/php-fpm/www.sock;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass phpfpm:9000;
            fastcgi_index   index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
} 
EOF
echo "Done"
echo "Creating index.php file in public"
cd ..
cd public
cat > index.php << EOF
<?php
phpinfo();
EOF
echo "Done"
cd ..
echo "Creating docker-compose file ..."
cat > docker-compose.yml << EOF 
version: '3'

services:
  #databse
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: password
    networks:
      - wpsite
  #php-fpm
  phpfpm:
    image: php:fpm
    depends_on:
      - db
    ports:
      - '9000:9000'
    volumes: ['./public:/usr/share/nginx/html']
    networks:
      - wpsite
  #phpmyadmin
  phpmyadmin:
    depends_on:
      - db
    image: phpmyadmin/phpmyadmin
    restart: always
    ports:
      - '8080:80'
    environment:
      PMA_HOST: db
      MYSQL_ROOT_PASSWORD: password
    networks:
      - wpsite
  #wordpress
  wordpress:
    depends_on: 
      - db
    image: wordpress:latest
    restart: always
    ports:
      - '8000:80'
    volumes: ['./:/var/www/html']
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    networks:
      - wpsite
  #nginx
  proxy:
    image: nginx:1.17.10
    depends_on:
      - db
      - wordpress
      - phpmyadmin
      - phpfpm
    ports:
      - '8001:80'
    volumes: 
      - ./:/var/www/html
      - ./nginx/default.conf:/etc/nginx/nginx.conf
    networks:
      - wpsite
networks:
  wpsite:
volumes:
  db_data:
EOF
echo "Done"
fuser -k 8000/tcp 9000/tcp 8081/tcp 8080/tcp
echo "Creating LEMP stck in docker for wordpress"
docker-compose up -d
echo "Servers created"

# prompting user to open site in browser
echo "Site is up and healthy. Open as.xvr.com in any browser to view it."
echo "Or click on the link -> http://localhost:8000"

# Adding subcommands to enbale/disable
if [ "$2" == "enable" ]; then
 docker-compose strat
elif [ "$2" == "disable" ]; then
 docker-compose stop
fi

# Adding subcommands to delete site
if [ "$2" == "delete" ]; then
 docker-compose down -v
 #removing hosts entry
 sed -i "/as.xvr.com/d" /etc/hosts
 #removing all local files
 rm -rf ./
fi

