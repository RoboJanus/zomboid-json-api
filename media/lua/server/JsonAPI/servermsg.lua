if isClient() then return end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end

    local checks = ""
    if SendCommandToServer then checks = checks .. "SendCommandToServer=yes " end
    if processSayMessage then checks = checks .. "processSayMessage=yes " end

    if args.message == "trysay" and processSayMessage then
        local ok, err = pcall(processSayMessage, "Hello from JSON API!")
        return '{"result":"processSayMessage: ' .. (ok and "worked" or JsonAPI.jsonEscape(tostring(err))) .. '"}'
    end

    if args.message == "trycmd" and SendCommandToServer then
        local ok, err = pcall(SendCommandToServer, "servermsg \"Hello from JSON API!\"")
        return '{"result":"SendCommandToServer: ' .. (ok and "worked" or JsonAPI.jsonEscape(tostring(err))) .. '"}'
    end

    return '{"globals":"' .. JsonAPI.jsonEscape(checks) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("servermsg", handleServerMsg)
    end
end)
