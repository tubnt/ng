po=$1
ip="207.ctalk.io"

lines=`docker ps --format "{ \"id\" : \"{{.ID}}\" , \"name\" : \"{{.Names}}\"}"`
lines=$(echo  $lines | jq --compact-output '{id: .id, name: .name}')
#echo $lines

for r in $lines
do
     id=`echo "$r" | jq .id  | sed 's/\"\(.*\)\"$/\1/g'`
     port=`echo "$r" | jq .name |  sed 's/\"\(.*\)\"$/\1/g'`

    if [ "$port" == "nginx1" ]; then
      continue
    fi

    if [[ -n $po  &&  "$po" != "$port" ]]; then
      continue
    fi

    p=""
    configs=`docker inspect $id --format '{{range .Config.Env}}{{.}}{{println}}{{end}}'`
    for c in $configs
    do
      if [ -n "$c" ]; then
	if [ `echo ${c%=*}` == "VNC_PW" ]; then
        	p=`echo ${c#*=}`
	fi
      fi
    done

    containerip=`docker inspect $port --format='{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`

p1=`cat /dev/urandom | head -n 10 | md5sum | head -c 10`
nginx=$(cat<<EOF
server {
        listen $port ssl;
        include /usr/local/openresty/nginx/cr/cr.conf;
  include /usr/local/openresty/nginx/cr/redis.conf;
        
  location / {
           access_by_lua_file '/usr/local/openresty/nginx/cr/ngx_lua_google_auth/accessa.lua';
           proxy_pass http://$containerip:6901;
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
     proxy_pass http://$containerip:6901;
           proxy_set_header X-Real-IP \$remote_addr;
        }
}
####luadb:$port:$p1
EOF
)

    rm -rf /data/openresty/conf.d/$port.conf
    rm -rf /data/openresty/cr/ga_saves/$port.save

    echo "$nginx" >/data/openresty/conf.d/$port.conf
    echo "https://$ip:$port 账户:$port 授权码:$p1 密码:$p"
done

