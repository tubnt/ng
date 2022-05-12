#!/bin/sh
time=`date`
log="/opt/log"
rip=`echo $2 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"  | head -n 1`
if [[ $1 = "stopsaklj21" ]];
        then
        mv /usr/local/openresty/nginx/conf/conf.d/* /usr/local/openresty/nginx/conf/bk/
        docker restart nginx1
        resul="stop ok.."
elif [[ $1 = "dkhshjhk2" ]];
        then
        mv /usr/local/openresty/nginx/conf/bk/* /usr/local/openresty/nginx/conf/conf.d/
        docker restart nginx1
        resul="start ok.."
        echo -e  "111\r\n$time/$rip/shell:$resul:\r\n$1/$2/\r\n" >> $log
elif [[ $1 = "restartdhcbeh13" ]];
        then
        if [[ $rip != "" ]];
        then
        containerip=`docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq) | grep "$rip" | grep -o '[0-9]\{4\}'`
        docker restart $containerip
        resul="$containerip:restart..."
        fi
fi
echo -e  "11\r\n$time/$rip/shell:$resul:\r\n$1/$2/\r\n" >> $log
~
