#!/bin/bash
DATABASE_PASS='admin123'

# installing MYSQL 
sudo apt update
sudo apt install mysql-server unzip -y
sudo systemctl start mysql
sudo systemctl enable mysql
mysql -V

# securing mysql
sudo mysql -e "alter user root@localhost identified with mysql_native_password by '$DATABASE_PASS'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
sudo mysql -u root -p"$DATABASE_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_PASS'"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# creating database & user
sudo mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE laraveldb"
sudo mysql -u root -p"$DATABASE_PASS" -e "CREATE USER 'laraveluser'@'%' IDENTIFIED WITH mysql_native_password BY '$DATABASE_PASS'"
sudo mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL ON laraveldb.* TO 'laraveluser'@'%'"

# installing PHP & Modules
sudo apt install php-fpm php-mysql php-common php-json php-mbstring php-zip php-xml php-cli php-curl php-tokenizer -y
php -v

# installing Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# installing NGINX & Laravel 
sudo apt install nginx -y

# configuring laravel
export COMPOSER_ALLOW_SUPERUSER=1;
cd /var/www
composer create-project --prefer-dist laravel/laravel laravelapp
sudo chown -R www-data.www-data /var/www/laravelapp/storage
sudo chown -R www-data.www-data /var/www/laravelapp/bootstrap/cache

# configuring nginx to serve laravel application
sudo cat > /etc/nginx/sites-available/laravelapp << 'EOL'

# prevent processing requests with undefined domains
server {
    listen      80;
    server_name "";
    return      404;
}

server {
    listen 80;
    server_name webapp.nakodevopsprojects.store;
    root /var/www/laravelapp/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}

EOL

sudo unlink /etc/nginx/sites-enabled/default  
sudo ln -s /etc/nginx/sites-available/laravelapp /etc/nginx/sites-enabled/ 
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

# enabling firewall & allow 22, 80, 443 ports
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
ufw --force enable
sudo ufw status

# adding user dev
sudo useradd -m -d /home/dev -s /bin/bash -G sudo dev
# User rules for dev
sudo echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev
