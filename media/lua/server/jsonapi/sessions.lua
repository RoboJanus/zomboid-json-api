if isClient() then return end

local function handleSessions(args)
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return '{"playerCount":0,"players":[]}' end
    local count = onlinePlayers:size()
    local playersJson = ""
    for i = 0, count - 1 do
        local p = onlinePlayers:get(i)
        local username = p:getUsername()
        local steamId = getSteamIDFromUsername(username) or "unknown"
        local name = username
        local desc = p:getDescriptor()
        if desc then
            local fn = desc:getForename() or ""
            local sn = desc:getSurname() or ""
            if fn ~= "" or sn ~= "" then name = fn .. " " .. sn end
        end
        if i > 0 then playersJson = playersJson .. "," end
        playersJson = playersJson .. '{"username":"' .. JsonAPI.jsonEscape(username) .. '","steamId":"' .. steamId .. '","name":"' .. JsonAPI.jsonEscape(name) .. '","x":' .. math.floor(p:getX()) .. ',"y":' .. math.floor(p:getY()) .. '}'
    end
    return '{"playerCount":' .. count .. ',"players":[' .. playersJson .. ']}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("sessions", handleSessions)
    end
end)
