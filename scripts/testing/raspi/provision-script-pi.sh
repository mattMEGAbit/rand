
#!/bin/bash

#variables 
$DBPASSWD=test123

# setting up a lemp stack on the raspi:

# update sources list 
sudo nano /etc/apt/sources.list
echo 'deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi' >> /etc/apt/sources.list

# paste this in -
deb http://mirrordirector.raspbian.org/raspbian/ stretch main contrib non-free rpi
# (php7 not in normal sources list)

sudo touch /etc/apt/preferences

# paste this in - 
echo 'Package: *' >> /etc/apt/preferences
echo 'Pin: release n=jessie' >> /etc/apt/preferences
echo 'Pin-Priority: 600' >> /etc/apt/preferences
# (stretch releases are not 100% stable so prefer jessie but since we need 
# php7 it will go looking in the stretch release)

sudo apt-get update
sudo apt-get dist-upgrade -y

# test install first 
sudo apt-get install -t stretch nginx -s

# install
sudo apt-get install -t stretch nginx -y

# get your ip address and check nginx is showing in browser 
ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'


# enter a root password for your database at the prompts - ie - test123
echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections

# install mysql 
sudo apt-get install mysql-server -y

# you can skip this step for your pi but not for production
# secure your mysql installation
sudo mysql_secure_installation
# VALIDATE PASSWORD PLUGIN (you can leave this 
# disabled because you use stong passwords)
# answer yes for everything else 
# find script on stackoverflow to fix this - I remember it was really simple

# install php 
sudo apt-get install -t stretch php7.0 php7.0-fpm php7.0-cli php7.0-opcache php7.0-mbstring php7.0-zip php7.0-json php7.0-xmlrpc php7.0-curl php7.0-gd php7.0-mcrypt php7.0-xml -y

# test install 
php -v

# modify PHP 7.0 FPM pool
sudo nano /etc/php/7.0/fpm/pool.d/www.conf

# change user and group references:
sed -i 's/user = www-data/user = pi/g' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = pi/g' /etc/php/7.0/fpm/pool.d/www.conf

# user = pi
# group = pi
# (ctrl+w - search)

# edit the default Nginx server block configuration file by typing:
sudo nano /etc/nginx/sites-available/default

# should look like this (without comments)

# server {
#     listen 80 default_server;
#     listen [::]:80 default_server;

#     root /var/www/html;
#     index index.html index.htm index.nginx-debian.html;

#     server_name _;

#     location / {
#         try_files $uri $uri/ =404;
#     }
# }

# what it should look like after 
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm index.nginx-debian.html;

    server_name server_domain_or_IP;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# test new configuration
sudo nginx -t

# reload to update changes 
sudo systemctl reload nginx

# create a test PHP file in our document root. Open a new file called info.php within your document root in your text editor here:
sudo touch /var/www/html/info.php

# make a new php file info.php
# past this in:
cat > /var/www/html/index.php <<'EOF'
<?php
phpinfo();
EOF

# go here to check its working 
http://server_domain_or_IP/index.php

# remove the file 
sudo rm /var/www/html/info.php

# create a new project 
sudo touch /var/www/html/index.php

# configure for multiple sites 
# figure out something similar to .htaccess file for nginx.





