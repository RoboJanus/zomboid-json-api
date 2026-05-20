local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "refreshInventory" then
        local player = getPlayer()
        if player then
            local inv = player:getInventory()
            inv:setDirty(true)
            inv:setDrawDirty(true)
            -- Force the inventory UI to refresh
            local pData = getPlayerData(0)
            if pData and pData.playerInventory then
                pData.playerInventory:refreshBackpacks()
            end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
