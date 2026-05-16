if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    local checks = ""
    if rcon then checks = checks .. "rcon=yes " end
    if executeCommand then checks = checks .. "executeCommand=yes " end
    if serverCommand then checks = checks .. "serverCommand=yes " end
    if getWorld then checks = checks .. "getWorld=yes " end
    if getCell then checks = checks .. "getCell=yes " end
    if saveGame then checks = checks .. "saveGame=yes " end
    if quit then checks = checks .. "quit=yes " end
    if shutdown then checks = checks .. "shutdown=yes " end
    if kick then checks = checks .. "kick=yes " end
    if kickUser then checks = checks .. "kickUser=yes " end
    if getPlayerByUserName then checks = checks .. "getPlayerByUserName=yes " end
    if getConnectedPlayers then checks = checks .. "getConnectedPlayers=yes " end
    if ServerLog then checks = checks .. "ServerLog=yes " end

    return '{"globals":"' .. JsonAPI.jsonEscape(checks) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
