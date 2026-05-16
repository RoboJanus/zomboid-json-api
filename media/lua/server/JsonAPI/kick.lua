if isClient() then return end

local function handleKick(args)
    local username = args.username
    if not username then return '{"error":"missing arg: username"}' end
    local reason = args.reason or "Kicked by admin"
    local connections = zombie.network.GameServer.udpEngine.connections
    for i = 0, connections:size() - 1 do
        local conn = connections:get(i)
        if conn.username == username then
            zombie.network.GameServer.kick(conn, reason, "admin")
            return '{"kicked":"' .. JsonAPI.jsonEscape(username) .. '","reason":"' .. JsonAPI.jsonEscape(reason) .. '"}'
        end
    end
    return '{"error":"player not found: ' .. JsonAPI.jsonEscape(username) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("kick", handleKick)
    end
end)
