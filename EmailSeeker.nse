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
    local emails = {}
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
        emails = join_array(emails)
        
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

            for email in string.gmatch(response.body, "[%l%d][%l%d%.]+@[%l][%l%d]+%.[%l%d%.]+") do
                if email then
                    email = email:gsub("%.$", "")
                    table.insert(emails, email)
                end
            end

			for email in string.gmatch(response.body, "[%l%d][%l%d%.]+[%(%{%[%<]at[%)%}%]%>][%l][%l%d]+%.[%l%d%.]+") do
                if email then
                    email = email:gsub("%.$", "")
                    table.insert(emails, email)
                end
            end
        end
    end

    if #emails > 0 then
        return emails
    end

    return "No emails found!"
end

