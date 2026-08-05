local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "itemDelivered" and args then
        -- Force inventory UI refresh so the server-added item appears immediately
        local playerInv = getPlayerInventory(0)
        if playerInv and playerInv.inventoryPane then
            playerInv.inventoryPane:refreshContainer()
        end

        -- Show chat notification
        if args.message then
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
end

Events.OnServerCommand.Add(onServerCommand)
