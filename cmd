#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cd "$(
    cd "$(dirname "$0")" || exit
    pwd
)" || exit
#====================================================
#====================================================
#====================================================

#fonts color
Green="\033[32m"
Red="\033[31m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"

shell_version="6.4"
openssl_version="1.1.1g"
jemalloc_version="5.2.1"

version_cmp="/tmp/console_install_version_cmp.tmp"
www_dir_path=`pwd`
ssl_dir_path="${www_dir_path}/web/nginx/cert"

git_host="git.gezi.vip"
git_user=""
git_pass=""
git_branch=""
go_check=""

THREAD=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
source '/etc/os-release'
VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')

judge() {
    if [[ 0 -eq $? ]]; then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}
webinstall() {
            read  -n1 -e -r -p  "是否暴露数据库端口(Y/n,默认回车为Y): " mysqlport
            if [[ "${mysqlport}" == "y" ]] ||  [[ "${mysqlport}" == "Y" ]] || [[ "${mysalport}" == "" ]]; then
			    sed -i "/# mysql ports value/c\      - \"33066:3306\" # mysql ports value" docker-compose.yml
            fi
            read  -n1 -e -r -p  "是否暴露phpmyadmin端口(Y/n,默认回车为Y): " phpmyadminport
            if [[ "${phpmyadminport}" == "y" ]] ||  [[ "${phpmyadminport}" == "Y" ]] || [[ "${phpmyadminport}" == "" ]]; then
                            sed -i "/# phpmyadmin ports value/c\      - \"3000:3000\" # phpmyadmin ports value" docker-compose.yml
            fi
            docker-compose up -d
	    docker-compose exec -u root  web /bin/sh -c 'pwd  && sh  /root/install.sh'
    	    mysqlpasswd=`docker-compose exec web /bin/sh -c "grep mysqlpasswd /root/nginxsetup.log | cut -d' ' -f2"`
	    servciestart
	    echo""
            echo -e "${OK} ${GreenBG} mysql端口开启成功：http://localhost:33066 ${Font}"
    	    echo -e "${OK} ${GreenBG} 数据库root密码: $mysqlpasswd  ${Font}"
            echo -e "${OK} ${GreenBG} phpmyadmin端口开启成功：http://localhost:3000 ${Font}"
            echo -e "${OK} ${GreenBG} 欢迎访问：http://localhost ${Font}"
}

ssl_judge_and_install() {
    read -rp "请输入你的域名信息(例如:www.abc.com):" domain
    mkdir -p $ssl_dir_path
    if [[ -f "$ssl_dir_path/web.key" || -f "$ssl_dir_path/web.crt" ]]; then
        echo "$ssl_dir_path 目录下证书文件已存在"
        echo -e "${OK} ${GreenBG} 是否删除 [Y/n]? ${Font}"
        read -r ssl_delete
        [[ -z ${ssl_delete} ]] && ssl_delete="Y"
        case $ssl_delete in
        [yY][eE][sS] | [yY])
            rm -rf "${ssl_dir_path}/*"
            echo -e "${OK} ${GreenBG} 已删除 ${Font}"
            ;;
        *) ;;

        esac
    fi

    if [[ -f "$ssl_dir_path/web.key" || -f "$ssl_dir_path/web.crt" ]]; then
        echo "证书文件已存在"
    elif [[ -f "$HOME/.acme.sh/${domain}_ecc/${domain}.key" && -f "$HOME/.acme.sh/${domain}_ecc/${domain}.cer" ]]; then
        echo "证书文件已存在"
        "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath "${ssl_dir_path}/web.crt" --keypath "${ssl_dir_path}/web.key" --ecc
        judge "证书应用"
    else
        ssl_install
        acme
	acme_cron_update
    fi

    cat >${ssl_dir_path}/ssl.conf <<EOF
listen 443 ssl http2;
server_name ${domain};

ssl_certificate       /usr/local/openresty/nginx/cert/web.crt;
ssl_certificate_key   /usr/local/openresty/nginx/cert/web.key;
ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
error_page 497  https://\$host\$request_uri;
EOF

    curpath="$(pwd)"
    cd "$www_dir_path"
    docker-compose exec   web /bin/sh -c "killall nginx && sleep 1 && nginx "
    cd $curpath
}

ssl_install() {
    if [[ "${ID}" == "centos" ]]; then
        yum install socat nc  -y
    else
        apt install socat netcat -y
    fi
    judge "安装 SSL 证书生成脚本依赖"

    curl https://get.acme.sh | sh
    judge "安装 SSL 证书生成脚本"
}

acme() {
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" -w ${www_dir_path}/web/nginx/html --standalone -k ec-256 --force --test; then
        echo -e "${OK} ${GreenBG} SSL 证书测试签发成功，开始正式签发 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        sleep 2
    else
        echo -e "${Error} ${RedBG} SSL 证书测试签发失败 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi

    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" -w ${www_dir_path}/web/nginx/html --server letsencrypt --standalone -k ec-256 --force; then
        echo -e "${OK} ${GreenBG} SSL 证书生成成功 ${Font}"
        sleep 2
        mkdir -p $ssl_dir_path
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath "${ssl_dir_path}/web.crt" --keypath "${ssl_dir_path}/web.key" --ecc --force; then
            echo -e "${OK} ${GreenBG} 证书配置成功 ${Font}"
            echo -e "${OK} ${GreenBG} 欢迎访问：https://localhost ${Font}"
            sleep 2
        fi
    else
        echo -e "${Error} ${RedBG} SSL 证书生成失败 ${Font}"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi
}

acme_cron_update() {
    ssl_update_file="$ssl_dir_path/update.sh"
    cat >$ssl_update_file <<EOF
#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /dev/null
"/root/.acme.sh"/acme.sh --installcert -d ${domain} --fullchainpath ${ssl_dir_path}/web.crt --keypath ${ssl_dir_path}/web.key --ecc
EOF
    chmod +x $ssl_update_file
    if [[ $(crontab -l | grep -c "update.sh") -lt 1 ]]; then
      if [[ "${ID}" == "centos" ]]; then
          sed -i "/acme.sh/c 0 3 * * 0 bash ${ssl_update_file}" /var/spool/cron/root
      else
          sed -i "/acme.sh/c 0 3 * * 0 bash ${ssl_update_file}" /var/spool/cron/crontabs/root
      fi
    fi
    judge "安装证书自动更新 "
}

servciestart() {
            echo -e "${OK} ${GreenBG} 正在启动服务... ${Font}"
	docker-compose exec -u root  web /bin/sh -c 'sh  /root/start.sh'
            echo -e "${OK} ${GreenBG} 服务启动完毕！ ${Font}"
}

servciestop() {
            echo -e "${OK} ${GreenBG} 正在停止服务... ${Font}"
	docker-compose exec -u root  web /bin/sh -c 'sh  /root/stopd.sh'
            echo -e "${OK} ${GreenBG} 服务已停止！ ${Font}"
}

servcierestartO() {
            echo -e "${OK} ${GreenBG} 正在停止服务... ${Font}"
	docker-compose exec -u root  web /bin/sh -c 'sh  /root/stopd.sh'
            echo -e "${OK} ${GreenBG} 正在启动服务... ${Font}"
	docker-compose exec -u root  web /bin/sh -c 'sh  /root/start.sh'
            echo -e "${OK} ${GreenBG} 服务重启成功！ ${Font}"
}

docker_compose_up_d() {
    curpath="$(pwd)"
    cd "$www_dir_path"
    echo -e "${OK} ${GreenBG} 开始重构服务... ${Font}"
    docker-compose up -d
    echo -e "${OK} ${GreenBG} 服务重构完成！ ${Font}"
    cd $curpath
}


mysql_bak() {
    mkdir -p /etc/mysql/bak
    filename="web$(date "+%Y%m%d%H%M%S").sql"
    mysqlpasswd=`docker-compose exec -T web /bin/sh -c "grep mysqlpasswd /root/nginxsetup.log | cut -d' ' -f2"`
    docker-compose exec web sh -c "mkdir -p /etc/mysql/bak && mysqldump -uroot -p$mysqlpasswd  --all-databases > /etc/mysql/bak/$filename"
    #docker-compose exec web /bin/sh -c "mkdir -p /etc/mysql/bak && mysqldump -uroot -p$mysqlpasswd  --all-databases > /etc/mysql/bak/$filename.sql"
    judge "备份数据库"
    [ -f "$filename" ] && echo -e "备份文件：$filename"
}

mysql_port_pass() {
    curpath="$(pwd)"
    cd "$www_dir_path"
    mysqlpasswd=`docker-compose exec web /bin/sh -c "grep mysqlpasswd /root/nginxsetup.log | cut -d' ' -f2"`
    echo -e "${OK} ${GreenBG} root密码: $mysqlpasswd  ${Font}"
    cd $curpath
}

uninstall_start() {
    read -rp "确定要卸载并且删除程序所有文件吗？(y/N): " uninstall
    [[ -z ${uninstall} ]] && uninstall="N"
    case $uninstall in
    [yY][eE][sS] | [yY])
        echo -e "${RedBG} 开始卸载... ${Font}"
        ;;
    *)
        echo -e "${GreenBG} 终止卸载。 ${Font}"
        exit 2
        ;;
    esac
    curpath="$(pwd)"
    cd "$www_dir_path"
    docker-compose rm -fs
    cd $curpath
    rm -rf "$www_dir_path/web"
    rm -rf "$www_dir_path/docker-compose.yml"
    cp -rf  $www_dir_path/.web $www_dir_path/web
    cp -rf  $www_dir_path/.docker-compose.yml $www_dir_path/docker-compose.yml
    if [[ "${ID}" == "centos" ]]; then
        sed -i '/'update.sh'/d' /var/spool/cron/root
    else
        sed -i '/'update.sh'/d' /var/spool/cron/crontabs/root
    fi
    echo -e "${OK} ${GreenBG} 卸载完成 ${Font}"
}

show_menu() {
    echo -e "—————————— 安装向导——————————"
    echo -e "${Green}A.${Font}  安装web平台（首次一键安装）"
    echo -e "${Green}B.${Font}  安装https证书（需要公网可用域名）"
    echo -e "${Green}C.${Font}  启动服务"
    echo -e "${Green}D.${Font}  停止服务"
    echo -e "${Green}E.${Font}  重启服务"
#    echo -e "${Green}F.${Font}  docker-compose up -d"
    echo -e "—————"
    echo -e "${Green}G.${Font}  备份数据库"
    echo -e "${Green}J.${Font}  查看数据库密码"
    echo -e "${Green}K.${Font}  ${Red}一键卸载${Font}"
    echo -e "${Green}Q.${Font}  退出脚本 \n"

    read -rp "请输入代码：" menu_num
    for menu_index in `seq 0 $((${#menu_num}-1))`
    do
        case $(echo "${menu_num:$menu_index:1}" | tr "a-z" "A-Z") in
        Q)
            exit 0
            ;;
        A)
	    webinstall
            ;;
        B)
	    ssl_judge_and_install
            ;;
        C)
            servciestart
            ;;
        D)
            servciestop
            ;;
        E)
            servcierestart
            ;;
#        F)
#            docker_compose_up_d
#            ;;
        G)
            mysql_bak
            ;;
        J)
            mysql_port_pass
            ;;
        K)
            uninstall_start
            ;;
        *)
            echo -e "${RedBG}请输入正确的操作代码${Font}"
            ;;
        esac
    done
}

show_menu
