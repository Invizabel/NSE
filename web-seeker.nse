local http = require "http"
local shortport = require "shortport"

-- HEAD --
description = [[
	Web Application Seeker
]]

author = "Invizabel"

portrule = function(host, port)
    return shortport.http(host, port) or shortport.ssl(host, port)
end

-- ACTION --
action = function(host, port)
    local options = {
        header = {
            ["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:154.0) Gecko/20100101 Firefox/154.0"
        },
		no_cache = true,
		bypass_cache = true
    }
    
    local target = host.targetname or host.ip
    local response = http.get(target, port.number, "/", options)
    
    if response.status == 200 and response.body then
        return "Address: " .. target .. " | Port: " .. port.number  .. " | Status: UP"
    end
end

