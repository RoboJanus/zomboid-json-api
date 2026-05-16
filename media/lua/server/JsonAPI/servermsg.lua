if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    -- Try GameServer.rcon which is in the B42 JavaDocs
    local result = "none"

    -- Pattern 1: direct global
    if GameServer then
        result = "GameServer global exists"
    end

    -- Pattern 2: via getGameServer (might be a LuaManager global)
    if not GameServer and getGameServer then
        result = "getGameServer exists"
    end

    -- Pattern 3: check if it's on the server object
    if not GameServer and isServer() then
        -- Try accessing via class reflection
        local ok, err = pcall(function()
            local gs = zombie.network.GameServer
            if gs then result = "zombie.network.GameServer works" end
        end)
        if not ok then result = "pcall error: " .. tostring(err) end
    end

    -- Pattern 4: try sendServerCommand which we know works
    if not GameServer then
        -- sendServerCommand is a known global - what about sendAdminMessage?
        local checks = ""
        if sendServerCommand then checks = checks .. "sendServerCommand=yes " end
        if sendAdminMessage then checks = checks .. "sendAdminMessage=yes " end
        if getOnlinePlayers then checks = checks .. "getOnlinePlayers=yes " end
        if getGameServer then checks = checks .. "getGameServer=yes " end
        if getServerOptions then checks = checks .. "getServerOptions=yes " end
        if ServerMap then checks = checks .. "ServerMap=yes " end
        if getServerMap then checks = checks .. "getServerMap=yes " end
        result = "globals: " .. checks
    end

    return '{"result":"' .. JsonAPI.jsonEscape(result) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
