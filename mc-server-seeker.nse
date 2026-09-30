local stdnse = require "stdnse"

-- HEAD --
description = [[
	Minecraft Java Server Seeker
]]

author = "Invizabel"

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
local function create_packet(data)
    return varint(#data) .. data
end

-- Receive response --
local function recieve_packet(socket)
    local data = ""
    local status, temp = socket:receive()
    data = data .. temp
    while status do
        local status, temp = socket:receive()
        if status then
            data = data .. temp
        else
            break
        end
    end
    return data
end

portrule = function(host, port)
	return port.protocol == "tcp"
		and port.state == "open"
end

-- ACTION --
action = function(host, port)
	local target = host.targetname or host.ip

    -- Create a socket  --
    local s = nmap.new_socket()
    s:set_timeout(10000)
    
    -- Connect to host --
    local status, error = s:connect(target, port)
    if not status then
            return "Connect failed: " .. error
    end
    
    local protocol = tonumber(stdnse.get_script_args("java.protocol")) or 777	

    -- Handshake --
    local handshake_data = varint(0) .. varint(protocol) .. varstring(host.ip) .. string.pack(">H", port.number) .. varint(1)
    local handshake = create_packet(handshake_data)
    -- End of handshake code --
    
    -- Send hanshake --
    s:send(handshake)
    local status, error = s:send(create_packet(varint(0)))

    if not status then
             return false, error
    end
    
    -- Receive response --
    local data = recieve_packet(s)
    s:close()
    
    -- Return processed response --
    if data then
            local start = data:find("{", 1, true)
            if start then
                    local out = data:sub(start)
                    
                    return "Address: " .. host.ip .. " | Port: " .. port.number .. " | Response: " .. out
            end
    end

	return "No response"
end
