local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "itemDelivered" and args and args.message then
        local player = getPlayer()
        if player then
            player:Say(args.message)
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
