if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    -- Use sendServerCommand to all connected players
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            p:Say(message)
        end
    end
    return '{"sent":true,"message":"' .. JsonAPI.jsonEscape(message) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
