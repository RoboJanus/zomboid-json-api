if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end
    getGameServer():sendServerCommand("servermsg", message)
    return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
