#!/bin/bash

# TODO setup secure password for root on db
# TODO make sure password isnt shown on the cmdline 
# TODO scp localfile user@host:/path/to/whereyouwant/thefile
# TODO disable root login, make another user to login that has to use sudo to become root after login move the authorized keys file to that users .ssh/ file. 

# ------------------------------------------------------------------------------------------------------

# Variables

YOURSITENAME=automatically_set

DBHOST=localhost
DBNAME=dbname
DBUSER=root
DBPASSWD=automatically_set
IP=automatically_set
LOGFILE=build.log
CURRENTDIR=pwd

echo -e "\n--- Making build.log file located in: $CURRENTDIR ---\n"

# make log file 
touch $LOGFILE

echo -e "\n--- Running ---\n"

echo -e "\n--- Updating packages list ---\n"

apt-get -y update

echo -e "\n--- Installing base packages ---\n"

apt-get -y upgrade  

echo -e "\n--- creating password for root ---\n"

DBPASSWD=$(echo -n @ && cat /dev/urandom | env LC_CTYPE=C tr -dc [:alnum:] | head -c 15) 

echo -e "\n--- root password for mysql is : $DBPASSWD ---\n"

echo "mysql-server mysql-server/root_password password $DBPASSWD" | debconf-set-selections

echo "mysql-server mysql-server/root_password_again password $DBPASSWD" | debconf-set-selections

echo -e "\n--- Install MySQL and set password for root ---\n"

apt-get -y install mysql-server 

mysql -u root -p$DBPASSWD -e "use mysql; UPDATE user SET authentication_string=PASSWORD('$DBPASSWD') WHERE User='root'; flush privileges;"

echo -e "\n--- Installing php-mysql php-fpm monit ---\n"

apt-get -y install php-mysql php-fpm monit 

echo -e "\n--- installing nginx ---\n"

echo -e "\n--- Adding nginx ppa ---\n"

add-apt-repository ppa:nginx/stable 

echo -e "\n--- apt-get update ---\n" 

apt-get -y update >> $LOGFILE

echo -e "\n--- Installing nginx ---\n" 

apt-get install -y nginx  

echo -e "\n--- saving current ip address IP ---\n"

IP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')

echo -e "\n--- restarting nginx php7.0-fpm monit ---\n"

systemctl start nginx php7.0-fpm monit

echo -e "\n--- enabling - mysql nginx php7.0-fpm monit - so they startup on boot ---\n"

systemctl enable mysql nginx php7.0-fpm monit

echo -e "\n--- provisioning other things now .. ---\n"

echo -e "\n--- making new nginx file .. ---\n"

cd /etc/nginx

mv nginx.conf nginx.conf.ORIG

cat > nginx.conf <<EOF
user  www-data;
worker_processes  auto;

pid /run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';
    error_log  /var/log/nginx_error.log error;
    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    # SSL
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # no sslv3 (poodle etc.)
    ssl_prefer_server_ciphers on;

    # Gzip Settings
    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_min_length 512;
    gzip_types text/plain application/x-javascript text/javascript application/javascript text/xml text/css application/font-sfnt;

    fastcgi_cache_path /usr/share/nginx/cache/fcgi levels=1:2 keys_zone=microcache:10m max_size=1024m inactive=1h;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

echo -e "\n--- checking if cache directory exists? ---\n"

ls /usr/share/nginx/html/

echo -e "\n--- creating cache directory ---\n"

mkdir -p /usr/share/nginx/cache/fcgi

echo -e "\n--- testing everything is working so far ---\n"

nginx -t

systemctl reload nginx

echo -e "\n--- install and setup php ---\n"

apt-get install php-json php-xmlrpc php-curl php-gd php-xml php-mbstring php-mcrypt php-xml 

mv /etc/php/7.0/fpm/php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf.ORIG

cat > /etc/php/7.0/fpm/php-fpm.conf <<EOF
[global]
pid = /run/php-fpm.pid
error_log = /var/log/php-fpm.log
include=/etc/php/7.0/fpm/pool.d/*.conf
EOF

cat > /etc/php/7.0/fpm/pool.d/www.conf <<EOF

[default]
security.limit_extensions = .php
listen = /var/run/php/${hostname}.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
user = www-data
group = www-data
pm = dynamic
pm.max_children = 75
pm.start_servers = 8
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500
EOF

echo -e "\n--- setting up php.ini file ---\n"

cd /etc/php/7.0/fpm/

mv php.ini php.ini.ORIG

cat > php.ini <<EOF
[PHP]
engine = On
short_open_tag = Off
asp_tags = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = Off
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 8M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
cgi.fix_pathinfo=0
file_uploads = On
upload_max_filesize = 25M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
[filter]
[iconv]
[intl]
[sqlite]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
[Phar]
[mail function]
SMTP = localhost
smtp_port = 25
mail.add_x_header = On
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"
[MySQL]
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[OCI8]
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatibility_mode = Off
mssql.secure_connection = Off
[Assertion]
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[mcrypt]
[dba]
[opcache]
[curl]
[openssl]
EOF

# Note - always remember to set cgi.fix_pathinfo=0 - 
# keeps php from guessing paths, it can be a security vuln.

echo -e "\n--- restarting php ---\n"

systemctl restart php7.0-fpm

echo -e "\n--- setting up mysql ---\n"

# http://stackoverflow.com/questions/24270733/automate-mysql-secure-installation-with-echo-command-via-a-shell-script
# http://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/

echo -e "\n--- Setting the database root password ---\n"
echo -e "\n--- Delete anonymous users ---\n"
echo -e "\n--- Ensure the root user can not log in remotely ---\n"
echo -e "\n--- Remove the test database ---\n"
echo -e "\n--- Flush the privileges tables ---\n"

mysql --user=root --password=$DBPASSWD <<EOF
UPDATE mysql.user SET authentication_string=PASSWORD('${DBPASSWD}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

echo -e "\n--- restarting mysql ---\n"

service mysql restart

echo -e "\n--- adding new user : $YOURSITENAME ---\n"

YOURSITENAME_LOGINPASSWD=$(echo -n @ && cat /dev/urandom | env LC_CTYPE=C tr -dc [:alnum:] | head -c 15) 

adduser --quiet --disabled-password --gecos "" $YOURSITENAME

echo "$YOURSITENAME:$YOURSITENAME_LOGINPASSWD" | sudo chpasswd

echo -e "\n--- make log file for your site ---\n"

mkdir -p /home/$YOURSITENAME/logs

echo -e "\n--- edit /etc/nginx/conf.d/$YOURSITENAME.conf ---\n"

cat > /etc/nginx/conf.d/$YOURSITENAME.conf <<EOF
server {
    listen       80;
    server_name  www.$YOURSITENAME;

    client_max_body_size 20m;

    index index.php index.html index.htm;
    root   /home/$YOURSITENAME/public_html;

    location / {
    
     	# below should look like this 
    	# try_files $uri $uri/ /index.php?q=$uri&$args;
    
        try_files $uri $uri/ /index.php?q=$uri&$args;
    }

    # pass the PHP scripts to FastCGI server
    location ~ \.php$ {
            # Basic
            try_files $uri =404;
            fastcgi_index index.php;

            # Create a no cache flag
            set $no_cache "";

            # Don't ever cache POSTs
            if ($request_method = POST) {
              set $no_cache 1;
            }

            # Admin stuff should not be cached
            if ($request_uri ~* "/(wp-admin/|wp-login.php)") {
              set $no_cache 1;
            }

            # WooCommerce stuff should not be cached
            if ($request_uri ~* "/store.*|/cart.*|/my-account.*|/checkout.*|/addons.*") {
              set $no_cache 1;
            }

            # If we are the admin, make sure nothing
            # gets cached, so no weird stuff will happen
            if ($http_cookie ~* "wordpress_logged_in_") {
              set $no_cache 1;
            }

            # Cache and cache bypass handling
            fastcgi_no_cache $no_cache;
            fastcgi_cache_bypass $no_cache;
            fastcgi_cache microcache;
            fastcgi_cache_key $scheme$request_method$server_name$request_uri$args;
            fastcgi_cache_valid 200 60m;
            fastcgi_cache_valid 404 10m;
            fastcgi_cache_use_stale updating;


            # General FastCGI handling
            fastcgi_pass unix:/var/run/php/$YOURSITENAME.sock;
            fastcgi_pass_header Set-Cookie;
            fastcgi_pass_header Cookie;
            fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_param SCRIPT_FILENAME $request_filename;
            fastcgi_intercept_errors on;
            include fastcgi_params;         
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff|ttf|svg|otf)$ {
            expires 30d;
            add_header Pragma public;
            add_header Cache-Control "public";
            access_log off;
    }

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}

# you will want to set this up unless your doing a subdomain
# performs a redirect if someone type the websitename.com instead 
# of www.websitname.com
# its just adding www to the beginning 
# if this were a subdomain with a specific address like 
# test.yoursitename.com you could just comment this out

server {
    listen       80;
    server_name  $YOURSITENAME;
    rewrite ^/(.*)$ http://www.$YOURSITENAME/$1 permanent;
}
EOF

echo -e "\n--- removing old nginx site ---\n"

# only need to do this once since this is most likely your first time setting things up.. 

ls /etc/nginx/sites-enabled/

rm /etc/nginx/sites-enabled/default

echo -e "\n--- setup php pool for the new site ---\n"

cat > /etc/php/7.0/fpm/pool.d/$YOURSITENAME.conf <<EOF
[$YOURSITENAME]
listen = /var/run/php/$YOURSITENAME.sock
listen.owner = $YOURSITENAME
listen.group = www-data
listen.mode = 0660
user = $YOURSITENAME
group = www-data
pm = dynamic
pm.max_children = 75
pm.start_servers = 8
pm.min_spare_servers = 5
pm.max_spare_servers = 20
pm.max_requests = 500

php_admin_value[upload_max_filesize] = 25M
php_admin_value[error_log] = /home/$YOURSITENAME/logs/phpfpm_error.log
php_admin_value[open_basedir] = /home/$YOURSITENAME:/tmp
EOF

echo -e "\n--- creating phpfpm_error.log file ---\n"

touch /home/$YOURSITENAME/logs/phpfpm_error.log

echo -e "\n--- listing out all users on the system ---\n"

ls /home

echo -e "\n--- creating password for : $YOURSITENAME ---\n"

YOURSITENAME_DBPASSWD=$(echo -n @ && cat /dev/urandom | env LC_CTYPE=C tr -dc [:alnum:] | head -c 15) 

echo -e "\n--- creating database for $YOURSITENAME ---\n"

mysql --user=root --password=$DBPASSWD <<EOF
CREATE DATABASE $YOURSITENAME;
CREATE USER $YOURSITENAME@localhost;
SET PASSWORD FOR $YOURSITENAME@localhost=PASSWORD('${YOURSITENAME_DBPASSWD}');
GRANT ALL PRIVILEGES ON $YOURSITENAME.* TO $YOURSITENAME@localhost IDENTIFIED BY '${YOURSITENAME_DBPASSWD}';
FLUSH PRIVILEGES;
EOF

echo -e "\n--- downloading wordpress ---\n"

wget https://wordpress.org/latest.tar.gz 

echo -e "\n--- Extract Wordpress Archive (+ Clean Up) ---\n"

tar zxf latest.tar.gz

rm latest.tar.gz

echo -e "\n--- Renaming the extracted 'wordpress' directory to public_html ---\n"

mv wordpress /home/$YOURSITENAME/public_html

echo -e "\n--- Setting proper file permissions on site files for : $YOURSITENAME ---\n"

cd /home/$YOURSITENAME/public_html

chown -R $YOURSITENAME:www-data .

find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

echo -e "\n--- Restarting services ---\n"

systemctl restart php7.0-fpm nginx

# echo -e "\n--- Secure the wp-config.php file so other users can’t read DB credentials ---\n"

# you would do this after you setup wordpress through the web browser

# chmod 640 /home/$YOURSITENAME/public_html/wp-config.php

echo -e "\n--- applying fix for : Nginx logs an error when started on a machine with a single CPU. ---\n"
  
mkdir /etc/systemd/system/nginx.service.d
  
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" > /etc/systemd/system/nginx.service.d/override.conf

systemctl daemon-reload

APPLIED_FIX=yes

echo -e "\n--- DONE!! ---\n"

echo -e "--------------------------------------------------------------------------------

basic info about install - copy/save somewhere SAFE/OFFSITE:

$LOGFILE location: $CURRENTDIR
acct login: $YOURSITENAME
acct password: $YOURSITENAME_LOGINPASSWD
acct database password: $YOURSITENAME_DBPASSWD
server name: $DBHOST
database name: $DBNAME
root database username: $DBUSER
root database password: $DBPASSWD
ip address: $IP

--------------------------------------------------------------------------------

applied fix for nginx : $APPLIED_FIX
if interested - see this: https://bugs.launchpad.net/ubuntu/+source/nginx/+bug/1581864

--------------------------------------------------------------------------------\n "
