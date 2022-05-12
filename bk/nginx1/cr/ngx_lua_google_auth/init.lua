require 'config'
gauth = require 'gauth'

local utila = require 'utila'

function userauth(port,user,pass)
        local port_number = tonumber(port)
        if port_number >= 8001 and port_number <= 8099 then
                port = user
        end

        local data = utila.get_data_by_port(user_gs_save_path,port)

        if data["sercret"] then
                local sercret = data['sercret']
                if gauth.Check(sercret, pass) then
                        return true
                end
        end

        return false

end

function get_user(port)
	headers = ngx.req.get_headers();
	local header =  headers['Authorization']
	ngx.log(ngx.ERR,  "header auth = " .. header)
	if header == nil or header:find(" ") == nil then
		return false
	end

	local divider = header:find(' ')
	if header:sub(0, divider-1) ~= 'Basic' then
		return false
	end

	local auth = ngx.decode_base64(header:sub(divider+1))
	if auth == nil or auth:find(':') == nil then
		return false
	end

	divider = auth:find(':')
	local user = auth:sub(0, divider - 1)
	local pass = auth:sub(divider + 1)

        local port_number = tonumber(port)
        if port_number >= 8001 and port_number <= 8099 then
		port = user		
	end 
       
	local data = utila.get_data_by_port(user_gs_save_path,port)
	
	if data["sercret"] then
		local sercret = data['sercret']
		if gauth.Check(sercret, pass) then
			return true
		end
        end

	return false
end

function set_cookie(port)
	local ck = require "resty.cookie"
	local cookie, err = ck:new()
	local expires_after = 3600
	local expiration = ngx.time() + expires_after
	local token = expiration .. ":" .. ngx.encode_base64(ngx.hmac_sha1(signature..port, expiration))

	local ok, err = cookie:set({
		key = "auth", value = token, path = "/",
		--domain = ngx.var.server_name..":"..port,
		httponly = true,
		--secure = true,
		expires = ngx.cookie_time(expiration), max_age = expires_after
	})
end

function authorization(port)

	local user = get_user(port)

	if user then
		
		return true
	else
		return false
	end
end

