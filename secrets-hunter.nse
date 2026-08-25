local http = require "http"
local shortport = require "shortport"
-- Credits: --
-- https://jaimepolop.github.io/RExpository --

-- HEAD --
description = [[
	Web Application Secrets Hunter
]]

author = "Invizabel"

local function join_array(arr)
    local seen = {}
    local result = {}

    for _, value in ipairs(arr) do
        if not seen[value] then
            seen[value] = true
            result[#result + 1] = value
        end
    end

    return result
end

local function mysplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

portrule = function(host, port)
    return shortport.http(host, port) or shortport.ssl(host, port)
end

-- ACTION --
action = function(host, port)
    local path = "/"
        
    local count = 0
    local secrets = {}
    local links = {}
    table.insert(links, path)

    local options = {
        header = {
            ["User-Agent"] = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:149.0) Gecko/20100101 Firefox/149.0"
        },
		no_cache = true,
		bypass_cache = true
    }
        
    while true do
        count = count + 1

        links = join_array(links)
        secrets = join_array(secrets)
        
        if count > #links then
            break
        end

        local response = http.get(host.targetname, port.number, links[count], options)
        
        if response.status == 200 and response.body then
			-- href --
            for link in string.gmatch(response.body, 'href="([^"]+)"') do
                if string.sub(link, 1, 1) == "/" then
                    table.insert(links, link)
                end
            end

		    -- src --
			for link in string.gmatch(response.body, 'src="([^"]+)"') do
				if string.sub(link, 1, 1) == "/" then
					table.insert(links, link)
				end
	        end
	
		    -- Adobe Client Id (Oauth Web) --
			for secret in string.gmatch(response.body, "(adobe[%l%d_ %.%,%-]{0,25})(=>|<=).{0,5}(['\"])([%x]{30})(['\"])") do
				if secret then
					table.insert(secrets, "Adobe Client Id (Oauth Web): " .. secret .. " | Path: " .. links[count])
				end
			end

			-- Abode Client Secret --
			for secret in string.gmatch(response.body, "(p8e%-)[%l%d]{32}") do
				if secret then
					table.insert(secrets, "Abode Client Secret: " .. secret .. " | Path: " .. links[count])
				end
			end

			-- Age Secret Key --
			for secret in string.gmatch(response.body, "AGE-SECRET-KEY-1[QPZRY9X8GF2TVDW0S3JN54KHCE6MUA7L]{58}") do
				if secret then
					table.insert(secrets, "Age Secret Key: " .. secret .. " | Path: " .. links[count])
				end
			end

			-- Airtable API Key --
			for secret in string.gmatch(response.body, "[\"']?air[%-_]?table[%-_]?api[%-_]?key(['\"])?[=:](['\"])?.+(['\"])\"") do
				if secret then
					table.insert(secrets, "Airtable API Key: " .. secret .. " | Path: " .. links[count])
				end
			end

			-- Alchemi API Key --
			for secret in string.gmatch(response.body, "(alchemi[%l%d_ %.%,%-]{0,25})(=>|<=).{0,5}(['\"])([%a%d%-]{32})(['\"])") do
				if secret then
					table.insert(secrets, Alchemi API Key: " .. secret .. " | Path: " .. links[count])
				end
			end
		end
	end

    if #secrets > 0 then
        return secrets
    end

    return "No secrets found!"
end

