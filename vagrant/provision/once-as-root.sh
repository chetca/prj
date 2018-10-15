#!/usr/bin/env bash

#== Import script args ==

timezone=$(echo "$1")

#== Bash helpers ==

USER='alex'
PASSWORD='password'

chmod -R 777 /app
chmod -R 777 /app/web


function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

export DEBIAN_FRONTEND=noninteractive

info "Enable russian locale"
sed -i '/^# ru_RU\.UTF-8 UTF-8/s/^#\s*//' /etc/locale.gen
locale-gen
echo "Done!"

info "Configure timezone"
timedatectl set-timezone ${TIMEZONE} --no-ask-password
echo "Done!"

info "Update OS software"
apt-get update
apt-get upgrade -y
echo "Done!"

info "Install Apache 2"
sudo apt-get install -y apache2
echo "Done!"

info "Add PHP 7.2 repository"
add-apt-repository ppa:ondrej/php -y
apt-get update
echo "Done!"

info "Install additional software"
apt-get install -y php7.2 php7.2-curl php7.2-cli php7.2-fpm php7.2-intl php7.2-mbstring php7.2-gd php7.2-zip php7.2-xml php7.2-mysql supervisor curl mc
echo "Done!"

info "Configure Apache"
info "Setup rewrite module"
ln -sf /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/
info "Setup site"
rm -f /etc/apache2/sites-enabled/000-default
cp -Rf /app/vagrant/apache2.conf/* /etc/apache2/
info "Restart"
/etc/init.d/apache2 restart
echo "Done!"

info "Prepare root password for MySQL (MariaDB)"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $PASSWORD"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $PASSWORD"
echo "Done!"

info "Install MariaDB 10.2"
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64] http://mirror.timeweb.ru/mariadb/repo/10.2/debian stretch main'
apt-get update
apt-get install -y mariadb-server
echo "Done!"

info "Configure MySQL"
mysql -uroot <<< "CREATE USER 'alex'@'localhost' IDENTIFIED BY 'password'"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'alex'@'localhost' WITH GRANT OPTION"
echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE yii2basic"
mysql -uroot <<< "CREATE DATABASE yii2basic_test"
echo "Done!"

info "Install phpmyadmin"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin php libapache2-mod-php
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
echo "Done!"

