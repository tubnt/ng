require 'config'
local utila = require 'utila'
local template = require "resty.template"
local session = require "resty.session"

local session = require "resty.session".open()
local hmac = ""
local timestamp = ""

local host = ngx.req.get_headers()['host']
local d = host:find(':')
local port = host:sub(d + 1)


local request_method = ngx.var.request_method
if request_method == "POST" then
        ngx.req.read_body()
        local user = ngx.req.get_post_args()["user"]
        local pass = ngx.req.get_post_args()["pass"]

        if  userauth(port,user,pass) then

                local expires_after = 3600*3
                local expiration = ngx.time() + expires_after
                local token = expiration .. ":" .. ngx.encode_base64(ngx.hmac_sha1(signature..port, expiration))

                --local session = require "resty.session".open()
                local sid = session.encoder.encode(session.id)

                session.data.port = port
                session.data.token = token
                session.data.last_time = ngx.time()
                session.data.last_ip = utila.getClientIp()
                session.expires = expiration
                session:save()

                local lock_name = port .. '.lock'
                local session_lock = session_gs_save_path .. '/' .. lock_name
                local old_lock = utila.read_file(session_lock)
                local last_ip = nil
                local last_time = nil
                if old_lock ~= nil then
                        local data = utila.unserialize(old_lock)
                        local old_session = session.encoder.decode(data['sid'])
                        last_ip = data['last_ip']
                        last_time = data['last_time']


                        local storage = session.strategy
                        local session_obj = {id=old_session}
                        --storage:destroy(session_obj)
                end

                local save_data = {}
                save_data.sid = sid
                save_data.last_time=ngx.time()
                save_data.last_ip=utila.getClientIp()

                local save_json = utila.serialize(save_data)
                utila.write_file(session_gs_save_path,lock_name, save_json)

                utila.log_report('authsuccess',port,last_time,last_ip)

                ngx.header.content_type = 'text/html'
                ngx.say("<html><head><script>location.href='/';</script></head></html>")
                ngx.exit(ngx.HTTP_OK)


       else
                utila.log_report('wrongpassword',port)
                ngx.header.content_type = 'text/html;charset=UTF-8'
                ngx.say("<html><head><script>alert('验证码错误');location.href='/auth/';</script></head></html>")
                ngx.exit(ngx.HTTP_OK)
      end
end

template.render("gaauth.html", { })
