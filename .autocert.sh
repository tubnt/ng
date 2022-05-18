#!/bin/sh
www_dir_path=/usr/local/openresty/nginx
ssl_dir_path=$www_dir_path/cert

ssl_judge_and_install() {
    mkdir -p $ssl_dir_path
    if [[ -f "$ssl_dir_path/web.key" || -f "$ssl_dir_path/web.crt" ]]; then
            rm -rf $ssl_dir_path/web.key
            rm -rf $ssl_dir_path/web.crt
    fi
        ssl_install
        acme

    cat >${ssl_dir_path}/ssl.conf <<EOF
server {
server_name ${domain};
    listen 443 ssl http2;

    ssl_certificate       /usr/local/openresty/nginx/cert/web.crt;
    ssl_certificate_key   /usr/local/openresty/nginx/cert/web.key;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    error_page 497  https://\$host\$request_uri;
    location / {
        root   ${www_dir_path}/html;
        index  index.html index.htm;
    }

}
EOF
    nginx -s reload
}

ssl_install() {
    apk add socat
    apk add netcat-openbsd 
    apk add curl
    apk add openssl
    apk add libressl
    echo "安装 SSL 证书生成脚本依赖"

    curl https://get.acme.sh | sh
    echo "安装 SSL 证书生成脚本"
}

acme() {
    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" -w ${www_dir_path}/html --standalone -k ec-256 --force --test; then
        echo  "SSL 证书测试签发成功，开始正式签发"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        sleep 2
    else
        echo  "SSL 证书测试签发失败"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi

    if "$HOME"/.acme.sh/acme.sh --issue -d "${domain}" -w ${www_dir_path}/html --server letsencrypt --standalone -k ec-256 --force; then
        echo "SSL 证书生成成功"
        sleep 2
        mkdir -p $ssl_dir_path
        if "$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath "${ssl_dir_path}/web.crt" --keypath "${ssl_dir_path}/web.key" --ecc --force; then
            echo  "证书配置成功"
            sleep 2
        fi
    else
        echo "SSL 证书生成失败"
        rm -rf "$HOME/.acme.sh/${domain}_ecc"
        exit 1
    fi
}

read -rp "请输入你的域名信息(例如:www.abc.com):" domain
ssl_judge_and_install
