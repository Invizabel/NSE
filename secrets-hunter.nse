local http = require "http"
local shortport = require "shortport"

-- HEAD --
description = [[
	Web Application PII, Sensitive Info, and Secrets Scraper
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

	    -- Grab emails --
            for email in string.gmatch(response.body, "[%a%d][%l%d%.]+@[%l][%l%d]+%.[%l%d%.]+") do
                if email then
                    email = email:gsub("%.$", "")
                    table.insert(secrets, email)
                end
            end

            -- Grab emails --
            for email in string.gmatch(response.body, "[%a%d][%l%d%.]+[%(%{%[%<]at[%)%}%]%>][%l][%l%d]+%.[%l%d%.]+") do
                if email then
                    email = email:gsub("%.$", "")
                    table.insert(secrets, email)
                end
            end

	    -- Grab phone numbers --
            for phone in string.gmatch(response.body, "tel%:%+?[%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-]") do
                if phone then
                    table.insert(secrets, phone)
                end
            end

            -- Grab phone numbers --
	    for phone in string.gmatch(response.body, "%(%d%d%%d)%-%d%d%d%-%d%d%d%d") do
                if phone then
                    table.insert(secrets, phone)
                end
            end

	    -- Grab phone numbers --
	    for phone in string.gmatch(response.body, "%(%d%d%d%) %d%d%d%-%d%d%d%d") do
                if phone then
                    table.insert(secrets, phone)
                end
            end

	    -- Grab phone numbers --
	    for phone in string.gmatch(response.body, "%d%d%d%-%d%d%d%-%d%d%d%d") do
                if phone then
                    table.insert(secrets, phone)
                end
            end

	    -- Grab local IP address --
	    for ip_address in string.gmatch(response.body, "10%.%d+%.%d+%.%d+") do
                if ip_address then
                    is_valid = true
                    verify = mysplit(ip_address, ".")
                    if verify then
                        for _, value in ipairs(verify) do
                            if value then
                                if tonumber(value) < 0 or tonumber(value) > 254 then
                                    is_valid = false
                                    break
                                end
                            end
                        end
                        if is_valid then
                            table.insert(secrets, ip_address)
                        end
                    end
                end
            end

            -- Grab local IP address --
	    for ip_address in string.gmatch(response.body, "172%.%d+%.%d+%.%d+") do
                if ip_address then
                    is_valid = true
                    verify = mysplit(ip_address, ".")
                    if verify then
                        for _, value in ipairs(verify) do
                            if value then
                                if tonumber(value) < 0 or tonumber(value) > 254 then
                                    is_valid = false
                                    break
                                end
                            end
                        end
                        if is_valid and tonumber(verify[2]) >= 16 and tonumber(verify[2]) <= 31 then
                            table.insert(secrets, ip_address)
                        end
                    end
                end
            end

            -- Grab local IP address --
	    for ip_address in string.gmatch(response.body, "192%.168%.%d+%.%d+") do
                if ip_address then
                    is_valid = true
                    verify = mysplit(ip_address, ".")
                    if verify then
                        for _, value in ipairs(verify) do
                            if value then
                                if tonumber(value) < 0 or tonumber(value) > 254 then
                                    is_valid = false
                                    break
                                end
                            end
                        end
                        if is_valid then
                            table.insert(secrets, ip_address)
                        end
                    end
                end
            end
        end
    end

    if #secrets > 0 then
        return secrets
    end

    return "No secrets found!"
end

