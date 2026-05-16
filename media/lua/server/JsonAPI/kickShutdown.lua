if isClient() then return end

local function handleKickShutdown(args)
    local reason = args.reason or "Safe Server Shutdown Initiated"
    local onlinePlayers = getOnlinePlayers()
    local kicked = 0
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            p:setKicked(reason)
            kicked = kicked + 1
        end
    end
    getGameServer():save()
    getGameServer():shutdown()
    return '{"kicked":' .. kicked .. ',"reason":"' .. JsonAPI.jsonEscape(reason) .. '","shutdown":true}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("kickShutdown", handleKickShutdown)
    end
end)
