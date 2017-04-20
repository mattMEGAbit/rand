
#!/bin/bash

echo [config.txt] >> config.txt

echo [php] >> config.txt

echo [main php ini file] -  >> config.txt

cat /etc/php/7.0/fpm/php.ini >> config.txt

echo [main php pool config] -  >> config.txt

cat /etc/php/7.0/fpm/pool.d/www.conf >> config.txt

echo [php-fpm config file] -  >> config.txt

cat /etc/php/7.0/fpm/php-fpm.conf  >> config.txt

echo [php-fpm sockets dir] -  >> config.txt

cat /var/run/php-fpm >> config.txt

echo [php-fpm vhost pool config file] >> config.txt

cat /etc/php/7.0/fpm/pool.d/yoursitename.conf >> config.txt

echo [nginx] >> config.txt

echo [serverblock file] -  >> config.txt

cat /etc/nginx/sites-available/default >> config.txt

echo [nginx conf file] -  >> config.txt

cat /etc/nginx/nginx.conf >> config.txt

echo [cache directory] -  >> config.txt

cat /usr/share/nginx/cache/fcgi >> config.txt

echo [nginx vhost config file] -  >> config.txt

cat /etc/nginx/conf.d/yoursitename.conf >> config.txt

echo [php-fpm vhost pool config file] -  >> config.txt

cat /etc/php/7.0/fpm/pool.d/yoursitename.conf >> config.txt

echo [php-fpm logfile] - >> config.txt

cat /home/SITENAME/logs/phpfpm_error.log >> config.txt

