if isServer() then return end

local function onGameStart()
    local player = getPlayer()
    if not player then return end
    local username = player:getUsername()

    -- Try various approaches to get Steam ID
    local sid1 = tostring(player:getSteamID())
    print("[JsonAPI] tostring(getSteamID): " .. sid1)

    local sid2 = string.format("%.0f", player:getSteamID())
    print("[JsonAPI] format %.0f: " .. sid2)

    local sid3 = string.format("%d", player:getSteamID())
    print("[JsonAPI] format %d: " .. sid3)

    -- Try getSteamIDFromUsername with different inputs
    local sid4 = getSteamIDFromUsername(username)
    print("[JsonAPI] getSteamIDFromUsername(username): " .. tostring(sid4))

    -- Try with Steam profile name
    local ok, steamName = pcall(function() return getSteamProfileName and getSteamProfileName() end)
    print("[JsonAPI] getSteamProfileName: " .. tostring(steamName))

    if ok and steamName then
        local sid5 = getSteamIDFromUsername(steamName)
        print("[JsonAPI] getSteamIDFromUsername(steamName): " .. tostring(sid5))
    end

    -- Send whatever we got
    local bestId = sid4 or sid3
    if bestId and bestId ~= "nil" then
        sendClientCommand("JsonAPI", "steamId", {steamId = bestId})
        print("[JsonAPI] Sent: " .. bestId)
    end
end

Events.OnGameStart.Add(onGameStart)
