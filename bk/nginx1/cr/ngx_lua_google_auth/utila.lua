require 'config'

local utila = {}
--[[
function utila.skipExt(str)
    local ext =  str:match(".+%.(%w+)$")
    local lists = {"js","jpg","png","doc","docx"}
    
end

function utila.in_array(b,list)
  if not list then
    return false  
  end 
    if list then
      for k, v in pairs(list) do
        if v.tableName ==b then
         return true
        end
      end
    end
end 
]]

function utila.file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

function utila.read_file(fileName)
    local f = io.open(fileName,'r')
    local content = oil
    if f then
       content = f:read('*all')
       f:close()
    end
    return content
end

function utila.write_file(savePath, fileName,data)

    local save_file = nil
    
    savePath = string.gsub(savePath, "\\", "\\\\")
    savePath = string.gsub(savePath, "[/\\]*$", "")
    save_file = savePath .. "/" .. fileName
    local f = io.open(save_file,'w')
    if f ~=nil then
       f:write(data)
       f:close()
    end
end

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function utila.randomStr(len)
  math.randomseed(os.time())
  local rankstr = ""
  if len > 0 then
    rankstr = utila.randomStr(len - 1) .. charset[math.random(1, #charset)]
  end

  return string.upper(rankstr)
end

function utila.get_data_by_port(savePath ,port)
    	savePath = string.gsub(savePath, "\\", "\\\\")
    	savePath = string.gsub(savePath, "[/\\]*$", "")
    	local data = nil
    	local file_name = savePath .. "/" .. port .. ".save"
    	local file_content = utila.read_file(file_name)
	if file_content ~= nil then
		data = utila.unserialize(file_content)
	end
    	return data
end

function utila.get_httpauth_by_port(conf_path,port)
    local file_name = conf_path .. "/" .. port..".conf"
    local auth = {}
    local file_content = utila.read_file(file_name)
    if file_content ~= nil then
        user,pass = string.match(file_content,'####luadb:(%w+):(%w+)')
        auth[user] = pass
    end
    
    return auth
end

function utila.has_ga_bind(savePath,port)
	savePath = string.gsub(savePath, "\\", "\\\\")
	savePath = string.gsub(savePath, "[/\\]*$", "")
	local file_path = savePath .. "/" .. port .. ".save"
        if not utila.file_exists(file_path) then
		return false
	end
	local data = utila.get_data_by_port(savePath,port)
	if data == nil then 
		return false
	end
	return data['isbind'] == 1
end

function utila.serialize(obj)
    local cjson2 = require "cjson"
    return cjson2.encode(obj)

end

function utila.unserialize(lua)
    local cjson2 = require "cjson"
    return cjson2.decode(lua)
end

function utila.getClientIp()
  IP = ngx.req.get_headers()["X-Real-IP"]
  if IP == nil then
    IP  = ngx.var.remote_addr 
  end
  if IP == nil then
    IP  = "unknown"
  end
  return IP
end

function utila.buildQuery(tab)
        local query = {}
        local sep = '&'
        local keys = {}
        for k in pairs(tab) do
                keys[#keys+1] = k
        end
        table.sort(keys)
        for _,name in ipairs(keys) do
                local value = tab[name]
                name = tostring(name)
                local value = tostring(value)
                if value ~= "" then
                        query[#query+1] = string.format('%s=%s', name, value)
                else
                        query[#query+1] = name
                end
        end
        return table.concat(query, sep)
end

function utila.log_report(commit, port, lasttime,lastip)
        local params={}
        params.commit=commit
	params.port=port
        params.lastip=lastip or ''
        params.lasttime=lasttime or ''
	params.ip=utila.getClientIp()
        local query=utila.buildQuery(params)
        local webhook_full_url = webhook_url .."&"..query
        os.execute("curl -s -o /dev/null '"..webhook_full_url.."'")
end


return utila
