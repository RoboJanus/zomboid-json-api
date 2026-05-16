if isClient() then return end

local function handleKickShutdown(args)
    local reason = args.reason or "Safe Server Shutdown Initiated"
    local connections = zombie.network.GameServer.udpEngine.connections
    local kicked = 0
    for i = 0, connections:size() - 1 do
        local conn = connections:get(i)
        if conn.username then
            zombie.network.GameServer.kick(conn, reason, "admin")
            kicked = kicked + 1
        end
    end
    zombie.network.ServerMap.instance:QueueSaveAll()
    zombie.network.GameServer.shutdown()
    return '{"kicked":' .. kicked .. ',"reason":"' .. JsonAPI.jsonEscape(reason) .. '","shutdown":true}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("kickShutdown", handleKickShutdown)
    end
end)
