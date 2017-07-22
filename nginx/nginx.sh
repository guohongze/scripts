#!/bin/bash
[ -f /data/server/nginx/bin/nginx ] && echo "nginx has installed" && exit 0
yum -y install gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel pcre-devel
cd /data/rpm
[ -f /data/rpm/nginx-1.8.1.tar.gz ] || wget http://nginx.org/download/nginx-1.8.1.tar.gz
tar zxvf nginx-1.8.1.tar.gz
mkdir -p /data/logs/nginx
chown -R nobody.nobody /data/logs/nginx
cd nginx-1.8.1
./configure \
--prefix=/data/server/nginx \
--user=nobody \
--group=nobody \
--error-log-path=/data/logs/nginx/error.log \
--http-log-path=/data/logs/nginx/access.log \
--with-http_realip_module \
--with-http_ssl_module \
--with-http_flv_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-pcre
make && make install
ln -s /data/server/nginx/sbin/nginx /usr/sbin/nginx
mkdir -p /data/server/nginx/conf/vhost
cp /data/scripts/nginx/files/nginx /etc/init.d
rm -rf /data/server/nginx/conf/nginx.conf
cp /data/scripts/nginx/files/nginx.conf /data/server/nginx/conf
cp /data/scripts/nginx/files/temp.conf /data/server/nginx/conf/vhost/temp.backup
chmod +x /etc/init.d/nginx
chkconfig --add nginx
chkconfig nginx on
rm -rf /data/rpm/nginx-1.8.1
mkdir -p /data/www
scp /data/scripts/files/index.php /data/www
scp /data/scripts/files/www.conf /data/server/nginx/conf/vhost
service nginx restart
echo "nginx installed successfully!"
