local http = require "http"
local shortport = require "shortport"

-- HEAD --
description = [[
	Web Application Contacts Scraper
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
    local contacts = {}
    local links = {}
    table.insert(links, path)

    local options = {
        header = {
            ["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:154.0) Gecko/20100101 Firefox/154.0"
        },
		no_cache = true,
		bypass_cache = true
    }
        
    while true do
        count = count + 1

        links = join_array(links)
        contacts = join_array(contacts)
        
        if count > #links then
            break
        end

		local target = host.targetname or host.ip
        local response = http.get(target, port.number, links[count], options)
        
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
				if string.sub(link, 1, 4) ~= "http" then
					table.insert(links, "/" .. link)
				end
	        end
	
		    -- Grab emails --
			for email in string.gmatch(response.body, "[%a%d][%l%d%.]+@[%l][%l%d]+%.[%l%d%.]+") do
				if email then
					email = email:gsub("%.$", "")
					table.insert(contacts, email)
				end
			end
	
			-- Grab emails --
			for email in string.gmatch(response.body, "[%a%d][%l%d%.]+[%(%{%[%<]at[%)%}%]%>][%l][%l%d]+%.[%l%d%.]+") do
				if email then
					email = email:gsub("%.$", "")
					table.insert(contacts, email)
				end
			end
	
		    -- Grab phone numbers --
			for phone in string.gmatch(response.body, "tel%:%+?[%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-][%d%-]") do
				if phone then
					table.insert(contacts, phone)
				end
			end
	
	        -- Grab phone numbers --
		    for phone in string.gmatch(response.body, "%(%d%d%%d)%-%d%d%d%-%d%d%d%d") do
				if phone then
					table.insert(contacts, phone)
				end
			end
	
		    -- Grab phone numbers --
		    for phone in string.gmatch(response.body, "%(%d%d%d%) %d%d%d%-%d%d%d%d") do
				if phone then
					table.insert(contacts, phone)
				end
	        end
	
		    -- Grab phone numbers --
		    for phone in string.gmatch(response.body, "%d%d%d%-%d%d%d%-%d%d%d%d") do
				if phone then
					table.insert(contacts, phone)
				end
	        end
		end
	end

    if #contacts > 0 then
        return contacts
    end

    return "No contacts found!"
end

