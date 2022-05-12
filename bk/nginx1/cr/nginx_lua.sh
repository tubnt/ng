#!/bin/sh

function notify_send ()
{
	#docker exec -it $1 /usr/bin/notify-send -t 0 -i user-info $2
	curl -s -o /dev/null  "http://172.105.0.1:9000/hooks/server?token=MNdjh13s23sd#21&commit=notify-send&port=$1&src_ip=$2&lasttime=$3"
}

port=$2
ip=$3
time=$4
if [ -n $time ]; then
	time=`date -d @$time "+%F %T"`
fi

case $1 in
	"authsuccess")
		notify_send $port $ip $time
		#notify_send $port "上次登陆时间:$time 上次登陆ip:$ip"
		#notify_send $port "请检查上次登陆信息是否正确"
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
