if isClient() then return end

local function handleAddItem(args)
    local username = args.username
    local itemType = args.item
    local count = tonumber(args.count) or 1
    if not username then return '{"error":"missing arg: username"}' end
    if not itemType then return '{"error":"missing arg: item"}' end
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if p:getUsername() == username then
                local sq = p:getCurrentSquare()
                if not sq then
                    return '{"error":"player has no current square"}'
                end
                local added = 0
                for c = 1, count do
                    local item = sq:AddWorldInventoryItem(itemType, 0.5, 0.5, 0.0)
                    if item then
                        added = added + 1
                    end
                end
                if added == 0 then
                    return '{"error":"invalid item type: ' .. JsonAPI.jsonEscape(itemType) .. '"}'
                end
                sendServerCommand(p, "JsonAPI", "itemDelivered", {item = itemType, count = tostring(added)})
                return '{"added":"' .. JsonAPI.jsonEscape(itemType) .. '","count":' .. added .. ',"to":"' .. JsonAPI.jsonEscape(username) .. '"}'
            end
        end
    end
    return '{"error":"player not found: ' .. JsonAPI.jsonEscape(username) .. '"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("additem", handleAddItem)
    end
end)
