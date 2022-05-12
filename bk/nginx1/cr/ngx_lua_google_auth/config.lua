-- auth router
auth_url = "/auth/"

host_white_list = {"admin.xxx.com"}

-- signature
signature = "httpauthfor#103.25.8.150"

-- user gs save path
session_gs_save_path = "/usr/local/openresty/nginx/cr/session_saves"
user_gs_save_path = "/usr/local/openresty/nginx/cr/ga_saves"
ga_bind_url = "https://150.ctalk.io:8000"
nginx_conf_path = "/usr/local/openresty/nginx/conf/conf.d"

webhook_url = "http://172.105.0.1:9000/hooks/server?token=MNdjh13s23sd"

-- user list
users = {}
users["beyondblog"] = "test"
