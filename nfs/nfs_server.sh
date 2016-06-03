#!/bin/bash
yum install -y nfs-utils
chkconfig rpcbind on
chkconfig nfs on
mkdir -p /data/nfs_share
echo "/data/nfs_share 10.100.1.0/24(rw,no_root_squash,no_all_squash,sync,anonuid=501,anongid=501)
" >> /etc/exports
service rpcbind start
service nfs start
