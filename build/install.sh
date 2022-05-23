#!/bin/sh

mysqlpasswd=`date +%s |  base64 | head -c 32`
redispasswd=`date +%s | sha256sum | head -c 32`
nginxworkdir=/usr/local/openresty/nginx
redisworkdir=/etc/redis.conf
phpworkdir=/etc/php7
phpmyadminworkdir=/usr/local/phpmyadmin
serviceworkdir=/root/serviceworkdir.log
nginxsetup=/root/nginxsetup.log
phpencrypt=`date +%s | sha256sum | base64 | head -c 32`

####nginx lua
nginxluainstall (){
mv /root/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
echo "nameserver 8.8.8.8" >>/etc/resolv.conf
apk update
apk upgrade
apk add make
apk add openrc
apk add psmisc
apk add gcc
apk add git
apk add outils-md5
apk add openssl
apk add unzip
mkdir -p /usr/local/lua
echo 'ngx.say("hello world");' > /usr/local/lua/index.lua
echo "Configure Directory: $nginxworkdir" >> $serviceworkdir
}
###redis
redisinstall (){
apk add redis
mkdir /run/redis
echo "requirepass $redispasswd" >> /etc/redis.conf
echo "redispasswd: $redispasswd" >> $nginxsetup
echo "Configure Directory: /etc/redis.conf" >> $serviceworkdir
}
###mysql
mysqlinstall (){
echo "fs.aio-max-nr=262144" >> /etc/sysctl.conf
sysctl -p
apk add mariadb mariadb-client
mkdir  /run/openrc
touch /run/openrc/softlevel
rm -rf /var/lib/mysql
mkdir /auth_pam_tool_dir
touch /auth_pam_tool_dir/auth_pam_tool
chown -R mysql:mysql /auth_pam_tool_dir
chmod -R 0770 /auth_pam_tool_dir
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
/usr/share/mariadb/mysql.server start
mysql -uroot -pmypasswd -e "use mysql;ALTER USER 'root'@'localhost' identified by '$mysqlpasswd';"
echo "mysqlpasswd: $mysqlpasswd" >> $nginxsetup
}
###php
phpinstall (){
apk add php7
apk add php7-mysqli php7-pdo_mysql php7-mbstring php7-json php7-zlib php7-gd php7-intl php7-session php7-fpm php7-memcached
apk add composer php-dom php-xml php-tokenizer php-xmlwriter
echo "listen = 127.0.0.1:9000" >>/etc/php7/php-fpm.conf
echo "Configure Directory: $phpworkdir" >> $serviceworkdir
}
###phpmyadmin
phpmyadmininstall (){
mkdir -p /usr/local/phpmyadmin
cd /usr/local/phpmyadmin
wget http://files.directadmin.com/services/all/phpMyAdmin/phpMyAdmin-5.2.0-all-languages.tar.gz
tar zxvf phpMyAdmin-5.2.0-all-languages.tar.gz
rm -rf /usr/local/phpmyadmin/phpMyAdmin-5.2.0-all-languages.tar.gz
mv phpMyAdmin-5.2.0-all-languages phpmyadmin
mkdir /usr/local/phpmyadmin/phpmyadmin/tmp
chmod -R 755 /usr/local/phpmyadmin
chmod 777 /usr/local/phpmyadmin/phpmyadmin/tmp
mv /usr/local/phpmyadmin/phpmyadmin/config.sample.inc.php /usr/local/phpmyadmin/phpmyadmin/config.inc.php
sed -i 's/\(\$cfg\['\''blowfish_secret'\''\] = '\''\)\('\'';\)/\1aofdgsz9x5dz77vdvzdeaz79asd\2/' /usr/local/phpmyadmin/phpmyadmin/config.inc.php
echo "Configure Directory: $phpmyadminworkdir" >> $serviceworkdir
mv /root/nginxphp.conf /usr/local/openresty/nginx/conf/nginx.conf
mysql -uroot -p$mysqlpasswd <<EOF
CREATE DATABASE phpmyadmin;
use phpmyadmin;
source /usr/local/phpmyadmin/phpmyadmin/sql/create_tables.sql;
EOF
}
###autocertificate
autocertificateinstall (){
apk add certbot
}
###收尾
end (){
apk add iproute2
rm -rf /var/cache/apk/*
rm -rf /root/nginxphp.conf
rm -rf /root/nginx.conf
}


echo -e "安装将默认配置nginx与lua环境,并可选装mysql、redis、php、phpmyadmin、cerbot"
read  -p  "是否安装mysql(Y/n,默认回车为Y): " mysql
read  -p  "是否安装redis(Y/n,默认回车为Y): " redis
read  -p  "是否安装php(Y/n,默认回车为Y): " php
read  -p  "是否安装phpmyadmin(Y/n,默认回车为Y): " phpmyadmin
read  -p  "是否安装自动证书工具(Y/n,默认回车为Y): " autocertificate

echo -e "正在安装nginx..."
nginxluainstall


if [[ "${mysql}" == "y" ]] || [[ "${mysql}" == "Y" ]] || [[ "${mysal}" == "" ]]; then
    echo -e "正在安装mysql..."
    mysqlinstall
fi

if [[ "${redis}" == "y" ]] || [[ "${mysql}" == "Y" ]] || [[ "${redis}" == "" ]]; then
    echo -e "正在安装redis..."
    redisinstall
fi

if [[ "${php}" == "y" ]] || [[ "${php}" == "Y" ]] || [[ "${php}" == "" ]]; then
    echo -e "正在安装php..."
    phpinstall
fi

if [[ "${phpmyadmin}" == "y" ]] || [[ "${phpmyadmin}" == "Y" ]] || [[ "${phpmyadmin}" == "" ]]; then
    echo -e "正在安装phpmyadmin..."
    phpmyadmininstall
fi

if [[ "${autocertificate}" == "y" ]] || [[ "${autocertificate}" == "Y" ]] || [[ "${autocertificate}" == "" ]]; then
    echo -e "正在安装自动证书..."
    autocertificateinstall
fi

end
echo ""
echo "==========================OK============================"
echo ""
echo  "服务启动脚本位于: /root/start.sh"
echo  "各项服务工作目录记录于: $serviceworkdir" 
echo  "nginx工作目录: $nginxworkdir"
if [[ "${mysql}" == "y" ]] ||  [[ "${mysql}" == "Y" ]] ||  [[ "${mysal}" == "" ]]; then
    echo  "mysql、redis密码位于: $nginxsetup"
    echo '#####mysql
    psmysql=`ps -a | grep "mysql" | grep -v "grep"`
    if [[ "$psmysql" = "" ]]
    then
        /usr/share/mariadb/mysql.server start
    fi' >> /root/start.sh
    echo 'killall mysqld' >> /root/stopd.sh
fi

if [[ "${redis}" == "y" ]] ||  [[ "${mysql}" == "Y" ]] ||  [[ "${redis}" == "" ]]; then
    echo  "redis工作目录: $redisworkdir"
    echo '####redis
    psredis=`ps -a | grep redis-server | grep -v grep`
    if [[ "$psredis" = "" ]]
    then
        nohup /usr/bin/redis-server /etc/redis.conf  2>&1 &
    fi' >> /root/start.sh
    echo 'kill -9  `ps -a |grep redis.conf |grep -v grep |awk '{print $1}'`' >> /root/stopd.sh
fi

if [[ "${php}" == "y" ]] ||  [[ "${php}" == "Y" ]] ||  [[ "${php}" == "" ]]; then
    echo  "php工作目录: $phpworkdir"
    echo '#####php-fpm7
    psphpfpm7=`ps -a | grep "php-fpm7" | grep -v "grep"`
    if [[ "$psphpfpm7" = "" ]]
    then
        /usr/sbin/php-fpm7
    fi' >> /root/start.sh
    echo ' killall php-fpm7' >> /root/stopd.sh
fi

if [[ "${phpmyadmin}" == "y" ]] ||  [[ "${phpmyadmin}" == "Y" ]] ||  [[ "${phpmyadmin}" == "" ]]; then
    echo  "phpmyadmin工作目录: $phpmyadminworkdir"
fi
exit 0
