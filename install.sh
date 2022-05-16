#!/bin/sh

mysqlpasswd=`date +%s |  base64 | head -c 32`
redispasswd=`date +%s | sha256sum | head -c 32`
nginxworkdir=/usr/local/openresty/nginx
redisworkdir=/etc/redis.conf
phpworkdir=/etc/php7
phpmyadminworkdir=/usr/local/phpmyadmin
serviceworkdir=/root/serviceworkdir.log
nginxsetup=/root/nginxsetup.log
startsh=/root/start.sh

####nginx lua
nginxluainstall (){
cp /root/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
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
echo "nginx" >> $startsh
echo "Configure Directory: $nginxworkdir" >> $serviceworkdir
}
###redis
redisinstall (){
apk add redis
mkdir /run/redis
echo "requirepass $redispasswd" >> /etc/redis.conf
echo "redispasswd: $redispasswd" >> $nginxsetup
echo "Configure Directory: /etc/redis.conf" >> $serviceworkdir
echo "nohup /usr/bin/redis-server /etc/redis.conf  &> /opt/redis.log &" >> $startsh
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
echo "/usr/share/mariadb/mysql.server start" >> $startsh
}
###php
phpinstall (){
apk add php7
apk add php7-mysqli php7-pdo_mysql php7-mbstring php7-json php7-zlib php7-gd php7-intl php7-session php7-fpm php7-memcached
apk add composer php-dom php-xml php-tokenizer php-xmlwriter
echo "listen = 127.0.0.1:9000" >>/etc/php7/php-fpm.conf
echo "Configure Directory: $phpworkdir" >> $serviceworkdir
echo "/usr/sbin/php-fpm7" >> $startsh
}
###phpmyadmin
phpmyadmininstall (){
mkdir -p /usr/local/phpmyadmin
cd /usr/local/phpmyadmin
wget http://files.directadmin.com/services/all/phpMyAdmin/phpMyAdmin-5.0.2-all-languages.tar.gz
tar zxvf phpMyAdmin-5.0.2-all-languages.tar.gz
rm phpMyAdmin-5.0.2-all-languages.tar.gz
mv phpMyAdmin-5.0.2-all-languages phpmyadmin
chmod -R 777 /usr/local/phpmyadmin
mv /usr/local/phpmyadmin/phpmyadmin/config.sample.inc.php /usr/local/phpmyadmin/phpmyadmin/config.inc.php
sed -i 's/\(\$cfg\['\''blowfish_secret'\''\] = '\''\)\('\'';\)/\1aofdgsaz79asd\2/' /usr/local/phpmyadmin/phpmyadmin/config.inc.php
echo "Configure Directory: $phpmyadminworkdir" >> $serviceworkdir
}
###autocertificate
autocertificateinstall (){
apk add certbot
}
###收尾
end (){
apk add iproute2
rm -rf /var/cache/apk/*
}


echo -e "执行本脚本默认将配置nginx与lua环境,并可选装mysql、redis、php、phpmyadmin、cerbot"
read  -p  "是否安装mysql(/n,直接回车为Y): " mysql
read  -p  "是否安装redis(y/n,直接回车为Y): " redis
read  -p  "是否安装php(y/n,直接回车为Y): " php
read  -p  "是否安装phpmyadmin(y/n,直接回车为Y): " phpmyadmin
read  -p  "是否安装自动证书工具(y/n,直接回车为Y): " autocertificate

echo -e "正在安装nginx..."
nginxluainstall


if [[ "${mysql}" == "y" ]] ||  [[ "${mysql}" == "Y" ]] ||  [[ "${mysal}" == "" ]]; then
    echo -e "正在安装mysql..."
    mysqlinstall
fi

if [[ "${redis}" == "y" ]] ||  [[ "${mysql}" == "Y" ]] ||  [[ "${redis}" == "" ]]; then
    echo -e "正在安装redis..."
    redisinstall
fi

if [[ "${php}" == "y" ]] ||  [[ "${php}" == "Y" ]] ||  [[ "${php}" == "" ]]; then
    echo -e "正在安装php..."
    phpinstall
fi

if [[ "${phpmyadmin}" == "y" ]] ||  [[ "${phpmyadmin}" == "Y" ]] ||  [[ "${phpmyadmin}" == "" ]]; then
    echo -e "正在安装phpmyadmin..."
    phpmyadmininstall
fi

if [[ "${autocertificate}" == "y" ]] ||  [[ "${autocertificate}" == "Y" ]] ||  [[ "${autocertificate}" == "" ]]; then
    echo -e "正在安装自动证书..."
    autocertificateinstall
fi

end

echo  "nginx工作目录: $nginxworkdir"
echo  "redis工作目录: $redisworkdir"
echo  "php工作目录: $phpworkdir"
echo  "phpmyadmin工作目录: $phpmyadminworkdir"
echo  "mysql、redis密码位于: $nginxsetup"
echo  "服务启动脚本位于: $startsh"
echo  "各项服务工作目录记录于: $serviceworkdir"
echo  "完成"
exit 0
