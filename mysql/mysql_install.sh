#!/bin/bash
# mysql install
#set -e
MYSQLDIR=/data/server/mysql

if [ -d $MYSQLDIR/bin ]
then
	echo "your linux has installed mysql!"
	read -p "uninstall mysql and beginning a new install?[y,n]" confirm
	case $confirm in
	yes|y|Y|Yes|YES) 
		echo "beginning clean install..."
		service mysqld stop
		rm -rf $MYSQLDIR
		rm -rf /usr/local/mysql
		rm -rf /etc/my.cnf
		rm -rf /data/logs/mysql
		rm -rf /etc/init.d/mysqld                     
		;;
	no|n|N|NO|No) 
		exit 1                    
		;;
	*) 
		exit 1                    
		;;
	esac
fi
echo "============================="
echo "====mysql install script====="
echo "============================="
[ ! -d /data/server ] && mkdir -p /data/server
[ ! -d /data/logs ] && mkdir -p /data/logs
cd /data/server
read -p "please type mysql version[default:5.6.29]:" mysqlv
if [ -z $mysqlv ] 
then
	mysqlv=5.6.29
fi
if [ -f /data/rpm/mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz ]
then
	scp /data/rpm/mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz /data/server
else
	ls /data/server|grep "mysql-$mysqlv-linux-glibc2.5"|xargs rm -rf
	wget  http://downloads.mysql.com/archives/get/file/mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz
fi
if [ $? -eq 1 ]
then
	echo "your mysql version is wrong!"
	exit 1
fi
echo "=============yum install packages=============="
yum install -y libaio ncurses ncurses-devel libaio-devel
tar zxvf mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz
mv mysql-$mysqlv-linux-glibc2.5-x86_64 mysql
cd $MYSQLDIR
mkdir -p temp
grep "mysql" /etc/group || groupadd mysql
grep "mysql" /etc/passwd || useradd -r -g mysql mysql -s /sbin/nologin
chown -R mysql:mysql .
$MYSQLDIR/scripts/mysql_install_db --user=mysql --basedir=$MYSQLDIR --datadir=$MYSQLDIR/data
scp support-files/mysql.server /etc/init.d/mysqld
ln -s $MYSQLDIR /usr/local/mysql
source /etc/profile
[ -f /etc/my.cnf ] && scp /etc/my.cnf my.cnf.$(date +%y%m%d).bak
echo "backup /etc/my.cnf my.cnf.$(date +%y%m%d).bak"
rm -rf /etc/my.cnf
rm -rf $MYSQLDIR/my.cnf
scp /data/scripts/mysql/my.cnf $MYSQLDIR
ln -s $MYSQLDIR/my.cnf /etc/my.cnf
[ ! -d /data/logs/mysql ] && mkdir -p /data/logs/mysql
chown -R mysql.mysql /data/logs/mysql
grep "$MYSQLDIR/bin" /etc/bashrc || echo "export PATH=$MYSQLDIR/bin:\$PATH" >> /etc/bashrc
source /etc/bashrc
[ -f /data/server/mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz ] && [ ! -f /data/rpm/mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz ] && mv /data/server/$mysqlv-linux-glibc2.5-x86_64.tar.gz /data/rpm/.
chkconfig mysqld on
rm -rf /data/server/mysql-$mysqlv-linux-glibc2.5-x86_64.tar.gz
echo "service mysqld start"
service mysqld start
echo "mysql install successfull!!"
