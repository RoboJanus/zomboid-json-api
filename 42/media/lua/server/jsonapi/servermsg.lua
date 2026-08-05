if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    local username = args.username
    if username then
        -- Send to a specific player only
        local players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                local p = players:get(i)
                if p:getUsername() == username then
                    sendServerCommand(p, "JsonAPI", "servermsg", {message = message})
                    return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '","to":"' .. JsonAPI.jsonEscape(username) .. '"}'
                end
            end
        end
        return '{"sent":false,"error":"player not found: ' .. JsonAPI.jsonEscape(username) .. '"}'
    else
        -- Broadcast to all players
        sendServerCommand("JsonAPI", "servermsg", {message = message})
        return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '"}'
    end
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
