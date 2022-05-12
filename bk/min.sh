#!/bin/sh
time=`date`
redis=`ps -a | grep redis-server | grep -v grep`
if [[ "$redis" != "" ]]
then
    echo "redis:yes">> /opt/log
 else
     echo "$time:redis:creating">> /opt/log
     nohup /usr/bin/redis-server /etc/redis.conf >> /opt/log 2>&1 &
fi
#####webhook
pswebhook=`ps -aux | grep "webhook/webhook" | grep -v "grep"`
if [[ "$pswebhook" != "" ]]
then
    echo "webhook:yes"
 else
     echo "$time:webhook:creating......"
     nohup /data/webhook/webhook -hooks /opt/webhook/docker.json -hooks /opt/webhook/s.json -hotreload -ip 127.0.0.1 -logfile /opt/log >> /opt/log 2>&1 &
fi
#####php-fpm7
psphpfpm7=`ps -aux | grep "php-fpm7" | grep -v "grep"`
if [[ "$psphpfpm7" != "" ]]
then
    echo "php-fpm7:yes"
 else
     echo "$time:php-fpm7:creating......"
     /usr/sbin/php-fpm7
fi
#####mysql
psmysql=`ps -aux | grep "mysql" | grep -v "grep"`
if [[ "$psmysql" != "" ]]
then
    echo "mysql:yes"
 else
     echo "$time:mysql:creating......"
     /usr/share/mariadb/mysql.server start
fi
####docerk healy
echo "$time:e.sh:start" >>/data/log
REDIS_HOST="127.0.0.1"
REDIS_PORT=6379
REDIS_DB=1
REDIS_AUTH="djhxbzjh376zha2"

MAX_CPU_LIMIT=80
MAX_MINUTES_LOOKING=60
LOG_FILE="/opt/log"

REDIS_CONNECT="/usr/bin/redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT}  -a ${REDIS_AUTH} -n ${REDIS_DB}"

lines=`docker stats --no-stream --format "{\"container\":\"{{ .Container }}\",\"memory\":{\"raw\":\"{{ .MemUsage }}\",\"percent\":\"{{ .MemPerc }}\"},\"cpu\":\"{{ .CPUPerc }}\"}"`
lines=$(echo  $lines | jq --compact-output '{id: .container, cpu: .cpu}')

for r in $lines
do
    id=`echo "$r" | jq .id | sed 's/\"\(.*\)\"$/\1/g'`
    cpu=`echo "$r" | jq .cpu | sed 's/\"\(.*\)\..*\"$/\1/g'`
   
    if [ $cpu -ge $MAX_CPU_LIMIT ]; then
	counting=`${REDIS_CONNECT} incr "${key}"`
	if [ $counting -lt $MAX_CPU_LIMIT ]; then

  	        ${REDIS_CONNECT} EXPIRE "${key}" 65
        	${REDIS_CONNECT} TTL "${key}"

	else

	       	docker restart $id
        	timenow=`date +"%Y-%m-%d %H:%M:%S"`

        	echo "[${timenow}] cpu ${cpu} on container ${id} , restarted" >> $LOG_FILE
	fi
    fi
done
