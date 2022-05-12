require 'config'
local utila = require 'utila'
local session = require "resty.session".open()

--local cookie = ngx.var.cookie_auth
local token = session.data.token
local hmac = ""
local timestamp = ""

ngx.log(ngx.ERR, token or "no token")

function whiteHost()
	if next(host_white_list) ~= nil then
		for _, host in pairs(host_white_list) do
			if ngx.var.host ==  host then
				return true
			end
		end
	end
	return false
end

if whiteHost() then
	return
end

local host = ngx.req.get_headers()['host']
local d = host:find(':')
local port = host:sub(d + 1)

local port_number = tonumber(port)
if not(port_number >= 8001 and port_number <= 8099) then
        if not  utila.has_ga_bind(user_gs_save_path,port) then
                local ga_bind_to = ga_bind_url .. '?code='..ngx.encode_base64(port)
                ngx.header.content_type = 'text/html'
                ngx.say("<html><head><script>location.href='"..ga_bind_to.."';</script></head></html>")
                ngx.exit(ngx.HTTP_OK)
                return
        end
end

if token ~= nil and token:find(":") ~= nil then
        local divider = token:find(":")
        hmac = ngx.decode_base64(token:sub(divider+1))
        timestamp = token:sub(0, divider-1)
        if ngx.hmac_sha1(signature..port, timestamp) == hmac and tonumber(timestamp) >= ngx.time() then
		ngx.log(ngx.ERR, "token check ok")
                return true
        end
	 ngx.log(ngx.ERR, "token check failed")
end

--session:regenerate()
ngx.exec("/auth/")
