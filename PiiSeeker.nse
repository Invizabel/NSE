local http = require "http"
local shortport = require "shortport"

-- HEAD --
description = [[
	Web Application Email Scraper
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

portrule = function(host, port)
    return shortport.http(host, port) or shortport.ssl(host, port)
end

-- ACTION --
action = function(host, port)
    local path = "/"
        
    local count = 0
    local pii = {}
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
        pii = join_array(pii)
        
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
            for email in string.gmatch(response.body, "[%l%d][%l%d%.]+@[%l][%l%d]+%.[%l%d%.]+") do
                if email then
                    email = email:gsub("%.$", "")
                    table.insert(pii, email)
                end
            end

			-- Grab emails --
			for email in string.gmatch(response.body, "[%l%d][%l%d%.]+[%(%{%[%<]at[%)%}%]%>][%l][%l%d]+%.[%l%d%.]+") do
                if email then
                    email = email:gsub("%.$", "")
                    table.insert(pii, email)
                end
            end

			-- Grab phone numbers --
            for phome in string.gmatch(response.body, "tel%:%+?[%d%-]{10,11}") do
                if phome then
                    phome = phome:gsub("%.$", "")
                    table.insert(pii, phome)
                end
            end

			-- Grab phone numbers --
			for phome in string.gmatch(response.body, "%(%d{3}%)%-%d{3}%-%d{4}") do
                if phome then
                    phome = phome:gsub("%.$", "")
                    table.insert(pii, phome)
                end
            end

			-- Grab phone numbers --
			for phome in string.gmatch(response.body, "%(%d{3}%) %d{3}%-%d{4}") do
                if phome then
                    phome = phome:gsub("%.$", "")
                    table.insert(pii, phome)
                end
            end

			-- Grab phone numbers --
			for phome in string.gmatch(response.body, "%d{3}%-%d{3}%-%d{4}") do
                if phome then
                    phome = phome:gsub("%.$", "")
                    table.insert(pii, phome)
                end
            end
        end
    end

    if #pii > 0 then
        return pii
    end

    return "No pii found!"
end

