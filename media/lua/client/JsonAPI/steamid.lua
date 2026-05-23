if isServer() then return end

local function onConnected()
    local player = getPlayer()
    if not player then return end
    local steamId = getSteamIDFromUsername(player:getUsername())
    if steamId then
        sendClientCommand("JsonAPI", "steamId", {steamId = steamId})
    end
end

Events.OnConnected.Add(onConnected)
