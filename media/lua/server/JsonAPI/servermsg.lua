if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    -- Try multiple access patterns
    local cs = nil
    local method = "none"

    if ChatServer then
        cs = ChatServer.getInstance()
        method = "ChatServer"
    end

    if not cs and zombie and zombie.network and zombie.network.chat and zombie.network.chat.ChatServer then
        cs = zombie.network.chat.ChatServer.getInstance()
        method = "zombie.network.chat.ChatServer"
    end

    if not cs then
        -- Try via getClassField reflection approach
        local available = ""
        if ChatServer then available = available .. "ChatServer=yes " else available = available .. "ChatServer=no " end
        if ServerChat then available = available .. "ServerChat=yes " else available = available .. "ServerChat=no " end
        if GameServer then available = available .. "GameServer=yes " else available = available .. "GameServer=no " end
        if ServerMap then available = available .. "ServerMap=yes " else available = available .. "ServerMap=no " end
        if ChatBase then available = available .. "ChatBase=yes " else available = available .. "ChatBase=no " end
        return '{"error":"no chat access","available":"' .. available .. '"}'
    end

    cs:sendServerAlertMessageToServerChat(message)
    return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '","method":"' .. method .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
