if isClient() then return end

local function handleStatus(args)
    local onlinePlayers = getOnlinePlayers()
    local count = 0
    if onlinePlayers then count = onlinePlayers:size() end
    return '{"playerCount":' .. count .. ',"serverName":"' .. JsonAPI.jsonEscape(getServerName()) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("status", handleStatus)
    end
end)
