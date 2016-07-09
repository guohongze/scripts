#backup.sh
#!/bin/sh
#on xtrabackup 2.2.8
# 第一次执行它的时候它会检查是否有完全备份,否则先创建一个全库备份
# 当你再次运行它的时候，它会根据脚本中的设定来基于之前的全备或增量备份进行增量备份

INNOBACKUPEX_PATH=innobackupex  #INNOBACKUPEX的命令
INNOBACKUPEXFULL=/usr/bin/$INNOBACKUPEX_PATH  #INNOBACKUPEX的命令路径

#mysql目标服务器以及用户名和密码
MYSQL_CMD="--host=localhost --user=root --password=gsa2088 --port=3306"  
MYSQL_UP=" --user=root --password='gsa2088' --port=3306 "  #mysqladmin的用户名和密码
TMPLOG="/data/logs/mysql/innobackupex.$$.log"
MY_CNF=/usr/local/mysql/my.cnf #mysql的配置文件
MYSQL=/usr/local/mysql/bin/mysql
MYSQL_ADMIN=/usr/local/mysql/bin/mysqladmin
BACKUP_DIR=/data/nfs2_backup/db # 备份的主目录
LOG_DIR=/$BACKUP_DIR/log # 日志的主目录
FULLBACKUP_DIR=$BACKUP_DIR/full # 全库备份的目录
INCRBACKUP_DIR=$BACKUP_DIR/incre # 增量备份的目录
FULLBACKUP_INTERVAL=86400 # 全库备份的间隔周期，时间：秒
KEEP_FULLBACKUP=7 # 至少保留几个全库备份
logfiledate=backup.`date +%Y%m%d%H%M`.txt

#开始时间
STARTED_TIME=`date +%s`

#############################################################################
# 显示错误并退出
#############################################################################

error()
{
    echo "$1" 1>&2
    exit 1
}

# 检查执行环境

if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULL未安装或未链接到/usr/bin."
fi

if [ ! -d $BACKUP_DIR ]; then
  error "备份目标文件夹:$BACKUP_DIR不存在."
fi

mysql_status=`netstat -nl | awk 'NR>2{if ($4 ~ /.*:3306/) {print "Yes";exit 0}}'`

if [ "$mysql_status" != "Yes" ];then
    error "MySQL 没有启动运行."
fi

if ! `echo 'exit' | $MYSQL -s $MYSQL_CMD` ; then
 error "提供的数据库用户名或密码不正确!"
fi

# 备份的头部信息

echo "----------------------------"
echo
echo "$0: MySQL备份脚本"
echo "开始于: `date +%F' '%T' '%w`"
echo

#新建全备和差异备份的目录

mkdir -p $FULLBACKUP_DIR
mkdir -p $INCRBACKUP_DIR
mkdir -p $LOG_DIR

#查找最新的完全备份
LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

# 查找最近修改的最新备份时间
LATEST_FULL_BACKUP_CREATED_TIME=`stat -c %Y $FULLBACKUP_DIR/$LATEST_FULL_BACKUP`

#如果全备有效进行增量备份否则执行完全备份
if [ "$LATEST_FULL_BACKUP" -a `expr $LATEST_FULL_BACKUP_CREATED_TIME + $FULLBACKUP_INTERVAL + 5` -ge $STARTED_TIME ] ; then
	# 如果最新的全备未过期则以最新的全备文件名命名在增量备份目录下新建目录
	echo -e "完全备份$LATEST_FULL_BACKUP未过期,将根据$LATEST_FULL_BACKUP名字作为增量备份基础目录名"
	echo "					   "
	NEW_INCRDIR=$INCRBACKUP_DIR/$LATEST_FULL_BACKUP
	mkdir -p $NEW_INCRDIR

	# 查找最新的增量备份是否存在.指定一个备份的路径作为增量备份的基础
	LATEST_INCR_BACKUP=`find $NEW_INCRDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n"  | sort -nr | head -1`
		if [ ! $LATEST_INCR_BACKUP ] ; then
			INCRBASEDIR=$FULLBACKUP_DIR/$LATEST_FULL_BACKUP
			echo -e "增量备份将以$INCRBASEDIR作为备份基础目录"
			echo "					   "
		else
			INCRBASEDIR=$INCRBACKUP_DIR/${LATEST_FULL_BACKUP}/${LATEST_INCR_BACKUP}
			echo -e "增量备份将以$INCRBASEDIR作为备份基础目录"
			echo "					   "
		fi

	echo "使用$INCRBASEDIR作为基础本次增量备份的基础目录."
	$INNOBACKUPEXFULL --defaults-file=$MY_CNF --use-memory=4G $MYSQL_CMD --incremental $NEW_INCRDIR --incremental-basedir $INCRBASEDIR > $TMPLOG 2>&1

	#保留一份备份的详细日志

	cat $TMPLOG>/$LOG_DIR/$logfiledate

	if [ -z "`tail -1 $TMPLOG | grep 'innobackupex: completed OK!'`" ] ; then
	 echo "$INNOBACKUPEX命令执行失败:"; echo
	 echo -e "---------- $INNOBACKUPEX_PATH错误 ----------"
	 cat $TMPLOG
	 rm -f $TMPLOG
	 exit 1
	fi

	THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPLOG`
	rm -f $TMPLOG


	echo -n "数据库成功备份到:$THISBACKUP"
	echo

	# 提示应该保留的备份文件起点

	LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

	NEW_INCRDIR=$INCRBACKUP_DIR/$LATEST_FULL_BACKUP

	LATEST_INCR_BACKUP=`find $NEW_INCRDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n"  | sort -nr | head -1`

	RES_FULL_BACKUP=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}

	RES_INCRE_BACKUP=`dirname ${INCRBACKUP_DIR}/${LATEST_FULL_BACKUP}/${LATEST_INCR_BACKUP}`

	echo
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo -e "必须保留$KEEP_FULLBACKUP份全备即全备${RES_FULL_BACKUP}和${RES_INCRE_BACKUP}目录中所有增量备份."
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo



else
	echo  "*********************************"
	echo -e "正在执行全新的完全备份...请稍等..."
	echo  "*********************************"
	$INNOBACKUPEXFULL --defaults-file=$MY_CNF  --use-memory=4G  $MYSQL_CMD $FULLBACKUP_DIR > $TMPLOG 2>&1 
	#保留一份备份的详细日志

	cat $TMPLOG>/$LOG_DIR/$logfiledate


	if [ -z "`tail -1 $TMPLOG | grep 'innobackupex: completed OK!'`" ] ; then
	 echo "$INNOBACKUPEX命令执行失败:"; echo
	 echo -e "---------- $INNOBACKUPEX_PATH错误 ----------"
	 cat $TMPLOG
	 rm -f $TMPLOG
	 exit 1
	fi

	 
	THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPLOG`
	rm -f $TMPLOG

	echo -n "数据库成功备份到:$THISBACKUP"
	echo

	# 提示应该保留的备份文件起点

	LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`

	RES_FULL_BACKUP=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}

	echo
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo -e "无增量备份,必须保留$KEEP_FULLBACKUP份全备即全备${RES_FULL_BACKUP}."
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #红色
	echo

fi

#删除过期的全备

echo -e "find expire backup file...........waiting........."
echo -e "寻找过期的全备文件并删除">>/$LOG_DIR/$logfiledate
for efile in $(/usr/bin/find $FULLBACKUP_DIR/ -mtime +6)
do
	if [ -d ${efile} ]; then
	rm -rf "${efile}"
	echo -e "删除过期全备文件:${efile}" >>/$LOG_DIR/$logfiledate
	elif [ -f ${efile} ]; then
	rm -rf "${efile}"
	echo -e "删除过期全备文件:${efile}" >>/$LOG_DIR/$logfiledate
	fi;
	
done

if [ $? -eq "0" ];then
   echo
   echo -e "未找到可以删除的过期全备文件"
fi

echo
echo "完成于: `date +%F' '%T' '%w`"
exit 0
