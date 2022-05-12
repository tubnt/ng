#!/bin/sh
time=`date`
/usr/sbin/crond
#####
u="/opt/sh/u.sh"
  if [[ ! -f "$u" ]]; then
     cp -r /opt/bk/u.sh  /opt/sh
     echo "$time:cp_u.sh">>/opt/log
     echo "$time:cp_u.sh"
  fi
###
cr="/usr/local/openresty/nginx/cr/webhook.conf"
  if [[ ! -f "$cr" ]]; then
     mkdir /usr/local/openresty/nginx/cr/ga_saves
     mkdir /usr/local/openresty/nginx/cr/session_saves
     cp -r /opt/bk/nginx1/cr /usr/local/openresty/nginx/cr
     chmod 777 /usr/local/openresty/nginx/cr/*
     echo "$time:cp_cr">>/opt/log
     echo "$time:cp_cr"
  fi
###
webhook="/opt/webhook/webhook"
  if [[ ! -f "$webhook" ]]; then
     cp -r /opt/bk/webhook /opt/
     chmod 777 /opt/webhook/*
     echo "$time:cp_webhook">>/opt/log
     echo "$time:cp_webhook"
  fi
######
/usr/sbin/php-fpm7
/usr/share/mariadb/mysql.server start
nohup /usr/bin/redis-server /etc/redis.conf >> /opt/log 2>&1 &
nohup /opt/webhook/webhook -hooks /opt/webhook/docker.json -hooks /opt/webhook/server.json -hotreload -ip 127.0.0.1 -logfile /opt/webhook/log >> /opt/log 2>&1 &   
echo "$time:start1">>/opt/log
/usr/local/openresty/bin/openresty -g 'daemon off;'
echo "$time:start2">>/opt/log
