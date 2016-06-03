#!/bin/bash
yum install -y nfs-utils
chkconfig rpcbind on
service rpcbind start
echo "10.100.1.1 nms1" >> /etc/hosts
mkdir -p /data/nms1_nfs
mount -t nfs4 nms1:/data/nfs_share /data/nms1_nfs
echo "mount -t nfs4 nms1:/data/nfs_share /data/nms1_nfs" >> /etc/rc.local