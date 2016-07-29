#!/bin/bash
yum install -y java-1.6.0 java-1.6.0-openjdk-devel
cp /nm1_share/zookeeper-3.4.6.tar.gz /data/server/
cd /data/server/
tar zxvf zookeeper-3.4.6.tar.gz
cd zookeeper-3.4.6
cp zookeeper-3.4.6/conf/zoo_sample.cfg zookeeper-3.4.6/conf/zoo.cfg
/data/server/zookeeper-3.4.6/bin/zkServer.sh start
echo "/data/server/zookeeper-3.4.6/bin/zkServer.sh start" >> /etc/rc.local
