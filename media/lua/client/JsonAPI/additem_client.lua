local function onServerCommand(module, command, args)
    if module ~= "JsonAPI" then return end
    if command == "itemDelivered" and args then
        local count = args.count or "1"
        local item = args.item or "item"
        local player = getPlayer()
        if player then
            player:Say("Received " .. count .. "x " .. item)
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
