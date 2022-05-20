#!/bin/sh

#####nginx
psnginx=`ps -a | grep "nginx" | grep -v "grep"`
if [[ "$psnginx" != "" ]]
then
    echo "nginx 已在运行中"
 else
    echo "nginx 启动中..."
    nginx
    echo "nginx 启动完毕"
fi
