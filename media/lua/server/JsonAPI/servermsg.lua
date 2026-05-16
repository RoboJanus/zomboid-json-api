if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end
    if not ChatServer then return '{"error":"ChatServer not available"}' end
    local instance = ChatServer.getInstance()
    if not instance then return '{"error":"ChatServer.getInstance() returned nil"}' end
    instance:sendServerAlertMessageToServerChat(message)
    return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
