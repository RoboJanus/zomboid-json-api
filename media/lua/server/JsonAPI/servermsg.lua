if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    -- Try saveGame
    local saveResult = "untested"
    if args.message == "save" then
        local ok, err = pcall(saveGame)
        saveResult = ok and "saveGame() worked" or ("saveGame error: " .. tostring(err))
        return '{"result":"' .. JsonAPI.jsonEscape(saveResult) .. '"}'
    end

    -- Probe getConnectedPlayers
    if args.message == "probe" then
        local players = getConnectedPlayers()
        if not players then return '{"result":"getConnectedPlayers returned nil"}' end
        local info = "type=" .. type(players) .. " size=" .. tostring(players:size())
        if players:size() > 0 then
            local p = players:get(0)
            info = info .. " class=" .. tostring(getClassName(p))
        end
        return '{"result":"' .. JsonAPI.jsonEscape(info) .. '"}'
    end

    return '{"result":"send message=save or message=probe"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
