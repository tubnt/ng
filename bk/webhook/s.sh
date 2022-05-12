#!/bin/sh
function log() {
	now=$(date "+%Y-%m-%d %H:%M:%S")
	echo "[ $now ] $1" >> /opt/webhook/log
}

function notify_send ()
{
	
	docker exec -i $1 /usr/bin/notify-send -t 0 -i user-info "$(echo -e $2)"
	log "done"
}

log "commit:$1 , lastip:$2 , lasttime:$3, port:$4"

commit=$1
lastip=$2
lasttime=`date -d @$3 "+%F %T"`
port=$4

case $commit in
        "authsuccess")
                notify_send $port "上次登陆时间: $lasttime\\n上次登陆ip: $lastip\\n请检查上次登陆信息是否正确"
        ;;

        "bindsuccess")
                echo $1
        ;;

        "wrongpassword")
                echo $1
        ;;

        *)
        echo "no command match, exit"
        exit 1
        ;;
esac
