#!/bin/bash
#php_easy_install 20160423 by GuoHongze 
set -e
if [ -f /usr/bin/php ]
then
	echo "your linux has install php!"
	exit 1
fi
read -p "please type php version[default:5.6.20]:" phpversion
if [ ! $phpversion ]
then
phpversion=5.6.20
fi
read -p "please input php-fpm max children(default:5):" max
if [ -z $max ]
then
        max=5
fi
read -p "please confirm you will install php-$phpversion and fpm children $max [y/n]" con1
case $con1 in
	yes|y) 
		echo "beginning install...."                     
		;;
	no|n) 
		exit 1                    
		;;
	*) 
		exit 1                    
		;;
esac
if [ -d /data/src ]
then
	echo
else
	mkdir /data/src
fi
cd /data/src
[ -f /data/src/php-$phpversion.tar.gz ] || wget http://cn2.php.net/distributions/php-$phpversion.tar.gz
tar zxvf php-$phpversion.tar.gz
cd /data/src/php-$phpversion
yum install -y gmp-devel \
readline-devel \
gcc \
gcc-c++ \
libicu-devel libicu \
ncurses ncurses-devel \
pcre pcre-devel \
libjpeg libjpeg-devel \
libpng libpng-devel \
freetype freetype-devel \
gettext gettext-devel \
libtiff libtiff-devel \
libxml2 libxml2-devel \
zlib zlib-devel \
glibc glibc-devel \
glib2 glib2-devel \
bzip2 bzip2-devel \
curl curl-devel  \
openssl openssl-devel \
openldap openldap-devel \
libXpm libXpm-devel \
gd gd-devel \
libmcrypt libmcrypt-devel \
libtool \
fontconfig fontconfig-devel
sleep 1
./configure \
--prefix=/data/server/php \
--with-config-file-path=/data/server/php/etc \
--disable-rpath \
--disable-debug \
--enable-fpm \
--with-fpm-user=nobody \
--with-fpm-group=nobody \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-mysql=mysqlnd \
--with-libxml-dir \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--enable-calendar \
--with-iconv-dir \
--enable-bcmath \
--with-zlib \
--with-zlib-dir \
--with-mcrypt \
--with-mhash \
--enable-opcache \
--enable-soap \
--enable-gd-native-ttf \
--enable-ftp \
--enable-mbstring \
--enable-exif \
--disable-ipv6 \
--with-pear \
--with-curl \
--enable-sockets \
--with-xpm-dir \
--with-openssl \
--enable-pcntl \
--enable-shmop \
--enable-sysvmsg \
--enable-sysvsem \
--enable-sysvshm \
--with-gettext \
--with-bz2 \
--enable-zip \
--enable-intl \
--with-xmlrpc \
--enable-inline-optimization 
make && make install
cp php.ini-production /data/server/php/etc/php.ini
ln -s /data/server/php/etc/php.ini /etc/php.ini
cp /data/server/php/etc/php-fpm.conf.default /data/server/php/etc/php-fpm.conf
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
ln -s /data/server/php/bin/php /usr/bin/php
chmod +x /etc/init.d/php-fpm
chkconfig php-fpm on

#config file
php_config=/data/server/php/etc/php.ini
fpm_config=/data/server/php/etc/php-fpm.conf
prc="date.timezone = PRC"
sed -i "926a $prc" $php_config
sed -i "1872a opcache.enable=1" $php_config
sed -i "1873a opcache.enable_cli=1" $php_config
sed -i "1874a opcache.memory_consumption=1024" $php_config
sed -i "1875a opcache.interned_strings_buffer=8" $php_config
sed -i "1876a opcache.max_accelerated_files=4000" $php_config
sed -i "1877a opcache.revalidate_freq=60" $php_config
sed -i "1878a opcache.fast_shutdown=1" $php_config
sed -i "1879a zend_extension=opcache.so" $php_config
sed -i "s/pm = dynamic/pm = static/g" $fpm_config
sed -i "s/pm.max_children = 5/pm.max_children = $max/g" $fpm_config
service php-fpm start
chkconfig php-fpm on
echo "install successful!"
