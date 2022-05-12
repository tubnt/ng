require 'config'
local utila = require 'utila'

local template = require "resty.template"
local gauth = require 'gauth'
local random = require 'random'
local basexx = require "basexx"

local session = require "resty.session".open()
local httpauth = session.data.httpauth
if httpauth == nil then
	session.data.httpauth = ''
	session:save()
end


local function save_data(save_path,host,port,sercret,qrcode,isbind)
                local save_name = port .. '.save'
                local save_data = {}

                save_data.host = host
                save_data.port = port
                save_data.sercret = sercret
		save_data.client_ip = utila.getClientIp()
                save_data.qrcode = qrcode
		save_data.isbind = isbind
	
                local write_json =utila.serialize(save_data)
                utila.write_file(save_path, save_name, write_json)
end

local csrf = ''
local code = ngx.req.get_uri_args()["code"]

if code == nil or code == '' then
	ngx.header.content_type = 'text/plain'
    	ngx.say("forbidden")
	ngx.exit(ngx.HTTP_FORBIDDEN)
	return
end

local port = ngx.decode_base64(code)
if port == nil or port == '' then
	ngx.header.content_type = 'text/plain'
        ngx.say("service unavailable")
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
	return
end

local conf_file_path = nginx_conf_path .. "/" ..  port..".conf"
if not utila.file_exists(conf_file_path) then
	ngx.header.content_type = 'text/plain'
        ngx.say("service unavailable")
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
	return
end

local function verifyCsrf(csrf)
    if csrf == nil or csrf:find(":") == nil then
    	return false
    end

    local divider = csrf:find(":")
    hmac = ngx.decode_base64(csrf:sub(divider+1))
    timestamp = csrf:sub(0, divider-1)
    if ngx.hmac_sha1(signature, timestamp) == hmac and tonumber(timestamp) >= ngx.time() then
         return true
    else
         return false
    end
end


local orign = ngx.req.get_headers()["host"]
local d = orign:find(':')
local host = orign:sub(0, d - 1)

local action = "https://"..orign.."?code="..code

local request_method = ngx.var.request_method

if httpauth ~= nil and httpauth ~= ''  then

	if not verifyCsrf(httpauth) then
		session:regenerate(true, false)
                ngx.header.content_type = 'text/html;charset=UTF-8'
                ngx.say("<html><head><script>alert('授权失效');location.href='"..action.."';</script></head></html>")
                ngx.exit(ngx.HTTP_OK)
	end 

        local sercret = ''
        local qrcode = ''


        local data = utila.get_data_by_port(user_gs_save_path,port)

        if data == nil or not data['sercret'] then
                local random_str = random.token(16)
                sercret = basexx.to_base32(random_str)
                sercret = string.sub(sercret,0,-7)
                qrcode = "otpauth://totp/"..port.."@"..host.."?secret="..sercret.."&issuer="..port

                save_data(user_gs_save_path,host,port,sercret,qrcode,0)
        else
                sercret = data['sercret']
                qrcode = data['qrcode']

                if data['isbind'] == 1 then
			session.destroy()
                        ngx.header.content_type = 'text/html;charset=UTF-8'
                        ngx.say("<html><head><script>alert('已绑定，请勿重复绑定');location.href='https://"..host..":"..port.."';</script></head></html>")
                        ngx.exit(ngx.HTTP_OK)
                end
        end


	if request_method == "POST" then
        	 ngx.req.read_body()
         	verifycode = ngx.req.get_post_args()["verifycode"]
        	if verifycode ~= nil and verifycode ~='' and gauth.Check(sercret, verifycode) then

		                save_data(user_gs_save_path,host,port,sercret,qrcode,1)
        		        utila.log_report('bindsuccess',port)
	
				session.destroy()
        		        local referer = "https://" .. host..":"..port
                		ngx.header.content_type = 'text/html;charset=UTF-8'
                		ngx.say("<html><head><script>alert('绑定成功');location.href='"..referer.."';</script></head></html>")
                		ngx.exit(ngx.HTTP_OK)
        	else
			        ngx.header.content_type = 'text/html;charset=UTF-8'
                                ngx.say("<html><head><script>alert('验证失败，请重试');location.href='"..action.."';</script></head></html>")
                                ngx.exit(ngx.HTTP_OK)	
	        end
	end

	

	template.render("gabind.html", { action=action, code = sercret , qrcode= qrcode})

else

        if request_method == "POST" then
                 ngx.req.read_body()
                local authcode = ngx.req.get_post_args()["authcode"]
	        local auth = utila.get_httpauth_by_port(nginx_conf_path,port)

	        if auth[port] and auth[port] == authcode then
	
			local expires_after = 60
        		local expiration = ngx.time() + expires_after
        		local token = expiration .. ":" .. ngx.encode_base64(ngx.hmac_sha1(signature, expiration))
        		session.data.httpauth = token
        		session:save()
                
			ngx.header.content_type = 'text/html;charset=UTF-8'
                        ngx.say("<html><head><script>location.href='"..action.."';</script></head></html>")
                        --ngx.say("ok")
			ngx.exit(ngx.HTTP_OK)		
	
		else
		        utila.log_report('wrongpassword',port)
                        ngx.header.content_type = 'text/html;charset=UTF-8'
                        ngx.say("<html><head><script>alert('授权码验证错误');location.href='"..action.."';</script></head></html>")
                        ngx.exit(ngx.HTTP_OK)			
		end
	end
	template.render("httpauth.html", { action=action})
end
