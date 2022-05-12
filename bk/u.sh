#!/bin/bash
#ip=`curl ifconfig.me`
ip="150.ctalk.io"
netname="em1"
version="s38z"
nversion="nginx5"
###
stop="a.ctalk.io:8050/hooks/webhook?token=42chsgeb213\&commit=stopsaklj21"
stop="sed -i "s#stopurl#${stop}#" /home/headless/Desktop/stop.desktop"
###
reboot="a.ctalk.io:8050/hooks/webhook?token=42chsgeb213\&commit=restartdhcbeh13"
reboot="sed -i "s#rebooturl#${reboot}#" /home/headless/Desktop/reboot.desktop"
###8000~8100网站端口,8100~9000远程端口
i=$2+2000
ni=$2
o=$2+3000
##
echo -e "\r\n $1 start: \r\n"
###################添加网卡
	unetwork=`docker network ls | grep ubuntu`
	if [[ "$unetwork" != "" ]]
	then
	    echo "ubuntu network:yes"
	 else
	     echo "ubuntu network:creating"
	     docker network create -d bridge ubuntu --subnet=172.200.0.0/24 --opt "com.docker.network.bridge.name"="ubuntu"
	fi
##################
	nnetwork=`docker network ls | grep nginx`
	if [[ "$nnetwork" != "" ]]
	then
	    echo "nginx network:yes"
	else
	     echo "nginx network:creating"
	docker network create -d bridge nginx --subnet=172.105.0.0/24 --opt "com.docker.network.bridge.name"="nginx"
fi

##################
for varible1 in $(seq 1 $3)
do
 i=$[$i+1];
 o=$[$o+1];
 ni=$[$ni+1];
##################
p=`cat /dev/urandom | head -n 10 | md5sum | head -c 10`
p1=`cat /dev/urandom | head -n 10 | md5sum | head -c 10`
comm="docker run -itd --name $ni"
comm=$comm" --add-host=account.wps.cn:127.0.0.1"
comm=$comm" --add-host=account.wpsdns.com:127.0.0.1 "
comm=$comm" --add-host=account.wps.com:127.0.0.1 "
comm=$comm" --add-host=ac.wpscdn.cn:127.0.0.1 "
comm=$comm" --add-host=vipapi.wpsdns.com:127.0.0.1 "
comm=$comm" --add-host=a.ctalk.io:172.105.0.2  "
comm=$comm" --add-host=h.ctalk.io:10.100.100.1  "
comm=$comm" --restart always "
comm=$comm" --network ubuntu"
#comm=$comm" -p $o:5901 "
#comm=$comm" -p $i:6901 "
comm=$comm" --shm-size 1g "
#comm=$comm" --user headless "
comm=$comm" -m=2g "
comm=$comm" --cpus=2 "
comm=$comm" -v /data/ubunt/sh:/etc/sh:ro "
comm=$comm" -v /etc/localtime:/etc/localtime:ro  "
comm=$comm" -v /data/ubunt/user/$ni/wj:/home/headless/Desktop/保存文件 "
comm=$comm" -e VNC_RESOLUTION=1280x800 "
comm=$comm" -e VNC_PW=$p"
comm=$comm" dyeeuw/second:$version"
###########
nginx=$(cat<<EOF
server {
        listen $ni ssl;
        include /usr/local/openresty/nginx/cr/cr.conf;
				include /usr/local/openresty/nginx/cr/redis.conf;
        location / {
          access_by_lua_file '/usr/local/openresty/nginx/cr/ngx_lua_google_auth/accessa.lua';
           proxy_pass http://izp:6901;
           proxy_http_version 1.1;
           proxy_set_header Upgrade \$http_upgrade;
           proxy_set_header Connection "Upgrade";
           proxy_set_header X-Real-IP \$remote_addr;
           proxy_connect_timeout 1d;
           proxy_send_timeout 1d;
           proxy_read_timeout 1d;
         }
				 location /auth/ {
				                 root   /usr/local/openresty/nginx/cr/html;
				                 default_type text/html;
				                 content_by_lua_file '/usr/local/openresty/nginx/cr/ngx_lua_google_auth/gacheck.lua';
				 }
        location ~ \.(images|img|javascript|js|css) {
	   proxy_pass http://izp:6901;
           proxy_set_header X-Real-IP \$remote_addr;
        }
}
####luadb:$ni:$p1
EOF
)
##################生成重启和停止
rebootok="docker exec -it $ni $reboot"
stopok="docker exec -it $ni $stop"
####
if [ $1 = "set" ] ; then
	echo "seting...."
	iptables -F
	iptables -t nat -F
	iptables -I FORWARD -i ubuntu -o ubuntu -j DROP
	iptables -I FORWARD -i ubuntu -o docker0 -j DROP
	iptables -t nat -I PREROUTING -p tcp --destination-port 8000:8300 -j DNAT --to 172.105.0.2
	iptables -t nat -A POSTROUTING -s 172.200.0.0/24 -o $netname -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 172.200.0.0/24 -o p1 -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 172.105.0.0/24 -o $netname -j MASQUERADE
	docker pull  dyeeuw/second:$version
	docker pull  dyeeuw/second:$nversion
	systemctl enable crond
	systemctl start crond
	crontab /etc/crontab
####VPN	
	#ip link add dev p1 type wireguard
	#ip address add dev p1 10.100.100.3/24
	#wg setconf p1 /etc/wireguard/p1.conf
	#ip link set p1 up
	#ip link del dev wg0 type wireguard
	#echo "seting.ok!"
elif [ $1 = "rm" ] ; then
	docker rm -vf $ni
	com=$com"\r\nrm--$ip:$ni"
	rm -rf /data/openresty/conf.d/$ni.conf
        rm -rf /data/openresty/cr/ga_saves/$ni.save
elif  [ $1 = "add" ] ; then
	$comm
	docker restart $ni
	com=$com"\r\n$ip:$ni--password:$p"
	echo "$nginx" >/data/openresty/conf.d/$ni.conf
elif  [ $1 = "restart" ] ; then
	docker restart $ni
	echo "restart:$ni:ok"
elif  [ $1 = "qadd" ] ; then
	docker rm -vf $ni
	$comm
	containerip=`docker inspect --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq) | grep $ni | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	nginx=`echo "$nginx" | sed "s/izp/${containerip}/g"`
	docker restart $ni
	rm -rf /data/openresty/conf.d/$ni.conf
	#rm -rf /data/openresty/cr/ga_saves/$ni.save
	#com=$com"\r\n$containerip-http://$ip:$i-https://$ip:$ni u:$ni p:$p1 vncp:$p"
	com=$com"\r\nhttps://$ip:$ni 账户:$ni 授权码:$p1 密码:$p"
	echo "$nginx" >/data/openresty/conf.d/$ni.conf
	$rebootok
	$stopok
else
     echo -e "批量重启restart:./u.sh retsart 开始端口 多少个\r\n批量删除rm:./u.sh rm 开始端口 多少个 \r\n添加容器add:./u.sh add 开始端口 多少个 \r\n强制添加慎用qadd:./u.sh qadd 开始端口 多少个"
fi
done
##################最后执行
	echo -e "\r\n nginx reload:"
	docker exec -it nginx1 nginx -s reload
	echo -e "result:r\n$com\nset iptables:"
	echo -e "\n$com" >>/root/log
	rm -rf  /data/openresty/conf.d/*.conf.swo
  rm -rf  /data/openresty/conf.d/*.conf.swp

