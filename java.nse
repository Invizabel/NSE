local stdnse = require "stdnse"

-- HEAD --
description = [[
Minecraft Java Server Seeker
]]

author = "Invizabel"


portrule = function(host, port)
	return port.protocol == "tcp"
		and port.state == "open"
end

-- ACTION --

action = function(host, port)
	-- Create a socket  --
	local s = nmap.new_socket()
	s:set_timeout(30000)
	
	-- Connect to host --
	local status, error = s:connect(host, port)
	if not status then
		return "Connect failed: " .. error
	end
	
	-- Start of handshake code --
	local handshake = "\x00"	

	local protocol = tonumber(stdnse.get_script_args("java.protocol")) or 776	

	local result = {}

	for i = 0, 4 do
		if protocol >> (7 * i) ~= 0 then
			local b = (protocol >> (7 * i)) & 0x7F
			local continuation = (protocol >> (7 * (i + 1))) ~= 0
			result[#result + 1] = string.char(b | (continuation and 0x80 or 0))
		end
	end	
	
	handshake = handshake .. table.concat(result)	

	local result = string.pack(">b", #host.ip) .. host.ip .. string.pack(">H", port.number) .. "\x01"	
	
	handshake = handshake .. result
	
	local handshake = string.pack(">b", #handshake) .. handshake
	-- End of handshake code --
	
	-- Send hanshake --
	s:send(handshake)
	local status, error = s:send("\x01\x00")

	if not status then
		 return false, error
	end
	
	-- Receive response --
	local data
	status, data = s:receive()
	s:close()
	
	-- Return processed response --
	if status then
		local start = data:find("{", 1, true)
		if start then
			local out = data:sub(start)
			return "Host: " .. host.ip .. " | Port: " .. port.number .. " | Response: " .. out
		end
	end

	-- Return no response detected --
	return "No Response"	
end

