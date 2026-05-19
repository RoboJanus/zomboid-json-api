if isClient() then return end

local function handleSave(args)
    saveGame()
    return '{"saved":true}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("save", handleSave)
    end
end)
