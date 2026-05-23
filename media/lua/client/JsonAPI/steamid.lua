if isServer() then return end

print("[JsonAPI] Client steamid.lua loaded")

local function onConnected()
    print("[JsonAPI] OnConnected fired")
    local player = getPlayer()
    if not player then
        print("[JsonAPI] ERROR: getPlayer() returned nil")
        return
    end
    local username = player:getUsername()
    print("[JsonAPI] Username: " .. tostring(username))
    local steamId = getSteamIDFromUsername(username)
    print("[JsonAPI] getSteamIDFromUsername result: " .. tostring(steamId))
    if steamId then
        sendClientCommand("JsonAPI", "steamId", {steamId = steamId})
        print("[JsonAPI] Sent steamId to server: " .. steamId)
    else
        print("[JsonAPI] ERROR: getSteamIDFromUsername returned nil")
    end
end

Events.OnConnected.Add(onConnected)
print("[JsonAPI] OnConnected handler registered")
