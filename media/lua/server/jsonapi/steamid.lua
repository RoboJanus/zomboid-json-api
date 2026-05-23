if isClient() then return end

-- Cache of username -> steamId (populated by client reports)
JsonAPI.steamIds = {}

local function onClientCommand(module, command, player, args)
    if module ~= "JsonAPI" or command ~= "steamId" then return end
    if player and args and args.steamId then
        local username = player:getUsername()
        JsonAPI.steamIds[username] = args.steamId
        print("[JsonAPI] Received Steam ID for " .. username .. ": " .. args.steamId)
    end
end

Events.OnClientCommand.Add(onClientCommand)
