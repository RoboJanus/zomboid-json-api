local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "refreshInventory" then
        local player = getPlayer()
        if player then
            player:getInventory():setDirty(true)
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
