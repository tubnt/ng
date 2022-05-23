#!/bin/sh

#####nginx
psnginx=`ps -a | grep "nginx" | grep -v "grep"`
if [[ "$psnginx" = "" ]]
then
    nginx
fi
