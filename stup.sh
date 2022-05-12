#!/bin/sh
####开始
echo "*       *       *       *       *       /opt/min.sh" >> /var/spool/cron/crontabs/root
echo "00 06 * * *  /opt/day.sh" >> /var/spool/cron/crontabs/root
echo "0 0 1 * * /opt/month.sh" >> /var/spool/cron/crontabs/root
####
mkdir -p /usr/local/openresty/nginx/conf/conf.d
mkdir -p /opt/sh
cp /opt/bk/nginx1/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
cp -r /opt/bk/nginx1/cr /usr/local/openresty/nginx/cr
cp -r /opt/bk/s.sh /opt
cp -r /opt/bk/day.sh /opt
cp -r /opt/bk/month.sh /opt
cp /opt/bk/u.sh  /opt/sh
cp /opt/bk/nginxrestore.sh /opt/sh
cp -r /opt/bk/webhook /opt/
chmod 777 /opt/webhook/*
chmod 777 /usr/local/openresty/nginx/cr/*
###
mkdir /usr/local/openresty/nginx/conf/bk/
mkdir /lib64
ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2
echo "nameserver 1.1.1.1" >>/etc/resolv.conf
apk update
apk upgrade 
apk add make
apk add openrc
apk add psmisc
apk add gcc
apk add git
apk add outils-md5
apk add openssl
apk add luarocks
wget --no-check-certificate https://luarocks.org/releases/luarocks-2.4.1.tar.gz
tar -xzvf luarocks-2.4.1.tar.gz
cd luarocks-2.4.1/
mkdir -p /usr/local/openresty/luajit/
./configure --prefix=/usr/local/openresty/luajit \
    --with-lua=/usr/local/openresty/luajit/ \
    --lua-suffix=jit \
    --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make build
make install
luarocks install lua-resty-cookie
luarocks install lua-resty-template
luarocks install lua-resty-session
apk add redis
apk add php7
apk add php7-mysqli php7-pdo_mysql php7-mbstring php7-json php7-zlib php7-gd php7-intl php7-session php7-fpm php7-memcached
apk add composer php-dom php-xml php-tokenizer php-xmlwriter
echo "listen = 127.0.0.1:9001" >>/etc/php7/php-fpm.conf
echo "slowlog=/opt/log" >>/etc/php7/php-fpm.conf
echo "request_slowlog_timeout=1s" >>/etc/php7/php-fpm.conf
echo "error_log =/opt/log" >>/etc/php7/php-fpm.conf
echo "error_log = "/opt/log"" >>/etc/php7/php.ini
###mysql
apk add mariadb mariadb-client
mkdir  /run/openrc
touch /run/openrc/softlevel
rm -rf /var/lib/mysql
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
/usr/share/mariadb/mysql.server start
mysql -uroot -pmypasswd -e "use mysql;ALTER USER 'root'@'localhost' identified by 'xzkjhhq378asdy&^Nhd';" 
###
apk add iproute2
mkdir /run/redis
echo "requirepass djhxbzjh376zha2" >> /etc/redis.conf
apk add certbot
rm -rf /var/cache/apk/*
rm -rf /luarocks-2.4.1.tar.gz
rm -rf /luarocks-2.4.1
