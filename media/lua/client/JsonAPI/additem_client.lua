local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "refreshInventory" and args then
        local player = getPlayer()
        if player and args.item then
            local count = tonumber(args.count) or 1
            local inv = player:getInventory()
            for i = 1, count do
                inv:AddItem(args.item)
            end
            inv:setDirty(true)
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
