if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end
    GameServer.sendAdminMessage(message, -1, -1, -1)
    return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
