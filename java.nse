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

-- Var Int Encoder --
local function varint(value)
    local out = {}

    repeat
        local byte = value & 0x7F
        value = value >> 7

        if value ~= 0 then
            byte = byte | 0x80
        end

        out[#out + 1] = string.char(byte)
    until value == 0

    return table.concat(out)
end

-- Var String Encoder --
local function varstring(str)
    return varint(#str) .. str
end

-- Create Packet --
local function packet(data)
    return varint(#data) .. data
end

action = function(host, port)
	-- Create a socket  --
	local s = nmap.new_socket()
	s:set_timeout(10000)
	
	-- Connect to host --
	local status, error = s:connect(host, port)
	if not status then
		return "Connect failed: " .. error
	end
	
	local protocol = tonumber(stdnse.get_script_args("java.protocol")) or 776	

	-- Handshake --
	local handshake_data = varint(0) .. varint(protocol) .. varstring(host.ip) .. string.pack(">H", port.number) .. varint(1)
	local handshake = packet(handshake_data)
	-- End of handshake code --
	
	-- Send hanshake --
	s:send(handshake)
	local status, error = s:send(packet(varint(0)))

	if not status then
		 return false, error
	end
	
	-- Receive response --
	local status, data = s:receive()
	s:close()
	
	-- Return processed response --
	if status then
		local start = data:find("{", 1, true)
		if start then
			local out = data:sub(start)
			return "Address: " .. host.name .. " | Port: " .. port.number .. " | Response: " .. out
		end
	end

	-- Return no response detected --
	return "No Response"	
end

