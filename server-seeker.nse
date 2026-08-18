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
    -- Check if server status is disabled
    local s = nmap.new_socket()
    s:set_timeout(10000)
    
    -- Connect to host --
    local status, error = s:connect(host, port)
    if not status then
            return "Connect failed: " .. error
    end
    
    -- Handshake --
    local handshake_data = varint(0) .. varint(protocol) .. varstring(host.ip) .. string.pack(">H", port.number) .. varint(2)
    local handshake = create_packet(handshake_data)
    -- End of handshake code --
    
    -- Send hanshake --
    s:send(handshake)

    -- Send client hello --
    local client_hello = create_packet(varint(0) .. varstring("Notch") .. "\x06\x9ay\xf4D\xe9G&\xa5\xbe\xfc\xa9\x0e8\xaa\xf5")
    local status, error = s:send(client_hello)
    
    if not status then
         return false, error
    end
    
    local data = recieve_packet(s)
    local out = stdnse.tohex(data):sub(-2)
    s:close()

    if out == "01" then
        return "Address: " .. host.ip .. " | Port: " .. port.number .. " | Response: " .. "likely a minecraft server but we can't query status, is it disabled?"
    end

    -- Return no response detected --
    return "No Response"
end
