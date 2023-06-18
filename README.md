# rtCampwordpress
Create a command-line script, preferably in Bash, PHP, Node, or Python to perform the following tasks:

Check if docker and docker-compose is installed on the system. If not present, install the missing packages.
The script should be able to create a WordPress site using the latest WordPress Version. Please provide a way for the user to provide the site name as a command-line argument.
It must be a LEMP stack running inside containers (Docker) and a docker-compose file is a must.
Create a /etc/hosts entry for example.com pointing to localhost. Here we are assuming the user has provided example.com as the site name.
Prompt the user to open example.com in a browser if all goes well and the site is up and healthy.
Add another subcommand to enable/disable the site (stopping/starting the containers)
Add one more subcommand to delete the site (deleting containers and local files).

Writing The Script
creating files
To create the script firstly, we have to create a file with any name for ex, script.sh (it should have .sh extention to be able to get executed as bash script)


touch script.sh
# use any editor of your choice
nano script.sh

Checking Docker
After opening the file, let's start witing our script. Initially, we have to check if docker and docker-compose are installed or not and if not present, install them.



#!/bin/bash

# Check if docker-compose is installed
if ! [ -x "$(command -v docker-compose)" ]; then
  # Install docker-compose if not present
  echo "Installing Docker Compose..."
  apt-get update
  apt-get install -y docker-compose
fi
This snippet of code will check for the above condition, here first we have to write #!/bin/bash.

Making Entry in /etc/hosts
To make an entry of the site name in host file, firstly we have to check if the site name is provided as an argument or not. if not, make the user do it.


# Check if site name argument was provided
if [ -z "$1" ]; then
  echo "Please provide a site name as an argument."
  exit 1
fi
# Entry in /etc/hosts
site_name="$1"
echo "127.0.0.1:8000 $site_name" >> /etc/hosts

Creating files
There are some required files for this LEMP stack to be operable and live, to create this either you can do it manually or just add it to the script and it will do it for you. I am going to add these to my script but you can do what you wish.


#creating required files
mkdir wordpress-docker
cd wordpress-docker
# Creating public and nginx
echo "Creating nginx configuration file"
mkdir public nginx
cd nginx
nano default.conf


Nginx config file:

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


Docker Compose file
This is the quite long Docker-compose file that I have written it took me around 1 hour to do so but in the end, it is worth it.

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
  #php
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
This Docker Compose file is for setting up a WordPress website with a MySQL database, PHP, PHPMyAdmin, Nginx, and WordPress itself.


Adding Sub commands

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
 sed -i "/$site_name/d" /etc/hosts
 #removing all local files
 rm -rf ./
fi
These subcommands will help users to perform other actions easily.


How to run this script
To run any script, we have to make it executable first. We can do this by running the following command in terminal

chmod +x script.sh


After making the script executable, we can run the script for the above operations to perform using the following command,

Note: It is MANDATORY to run the script as an administrator or superuser


sudo ./script.sh SITE_NAME
Note: Here you have to provide the site name as an argument.

By running the script, it will perform the above-mentioned task. It creates 5 different docker containers running the LEMP stack (with phpmyadmin). If everything goes well, you can visit your WordPress site by opening it in the browser using either site_name or Localhost.

Running Subcommands
There are some sub-commands available in the script to perform operations like stopping, starting/restarting, and deleting the containers. To run the sub-commands you need to add it to the main command as an argument for example,

To start/Restart the containers,

./script.sh SITE_NAME enable
To Stop the containers,

./script.sh SITE_NAME disable
To Delete the containers,

./script.sh SITE_NAME delete
