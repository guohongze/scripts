#!/bin/bash
REPO=$1
error()
{
    echo "$1" 1>&2
    exit 1
}
if [ -z $REPO ];then
        error "shell script exit,please give a repo name!example: ./svn_create.sh repo_name"
fi
SVN_CONF=/data/scripts/svn/files/svnserve.conf
svnadmin create /data/svn/$REPO
sed "s/website_v2/$REPO/g" $SVN_CONF > /data/svn/$REPO/conf/svnserve.conf
echo "[$REPO:/]" >> /data/svn/conf/authz
echo "@admin = rw" >> /data/svn/conf/authz
echo "* =" >> /data/svn/conf/authz
#cp -f /data/shell/src/pre-commit /data/svn/$REPO/hooks/.
#sed "s/website_v2/$REPO/g" /data/shell/src/post-commit > /data/svn/$REPO/hooks/post-commit
#chmod +x /data/svn/$REPO/hooks/post-commit
#mkdir -p /data/www/$REPO
#svn co file:///data/svn/$REPO /data/www/$REPO
#mkdir -p /data/www/$REPO/trunk
#mkdir -p /data/www/$REPO/brunches
#mkdir -p /data/www/$REPO/tags
#svn add /data/www/$REPO/*
#svn ci /data/www/$REPO/* -m 'create brunches'
echo "create svn $REPO repo finished."
