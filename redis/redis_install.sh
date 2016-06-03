#!/bin/bash
mkdir -p /data/rpm
cd /data/rpm
[ -f /data/rpm/redis-3.2.0.tar.gz ] || wget http://download.redis.io/releases/redis-3.2.0.tar.gz
tar zxvf redis-3.2.0.tar.gz
mv redis-3.2.0 /data/server/redis
cd /data/server/redis
make
cp /data/scripts/redis/files/redis /etc/init.d
rm -rf /data/server/redis/redis.conf
cp /data/scripts/redis/files/redis.conf /data/server/redis/redis.conf
chmod +x /etc/init.d/redis
ln -s /data/server/redis/src/redis-cli /usr/bin/redis-cli
chkconfig redis on
service redis start
service redis status