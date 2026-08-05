local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "servermsg" and args and args.message then
        if not ISChat.instance or not ISChat.instance.chatText then return end
        local message = "<RGB:0.6,0.9,1> [Server] " .. args.message
        local msg = {
            getText = function(_) return message end,
            getTextWithPrefix = function(_) return message end,
            isServerAlert = function(_) return true end,
            isShowAuthor = function(_) return false end,
            getAuthor = function(_) return "" end,
            setShouldAttractZombies = function(_) return false end,
            setOverHeadSpeech = function(_) return false end,
        }
        ISChat.addLineInChat(msg, 0)
    end
end

Events.OnServerCommand.Add(onServerCommand)
