if isClient() then return end

local function handlePlayerStats(args)
    local username = args and args.username
    if not username then
        return '{"error":"username required"}'
    end

    local players = getOnlinePlayers()
    local target = nil
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p:getUsername() == username then
            target = p
            break
        end
    end

    if not target then
        return '{"error":"player not found"}'
    end

    local hours = target:getHoursSurvived()
    local kills = target:getZombieKills()

    -- Gather skill levels
    local perks = {
        "Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble",
        "Sneak", "Axe", "Blunt", "SmallBlunt", "LongBlade",
        "SmallBlade", "Spear", "Maintenance", "Woodwork",
        "Cooking", "Farming", "Doctor", "Electricity",
        "MetalWelding", "Mechanics", "Tailoring", "Aiming",
        "Reloading", "Fishing", "Trapping", "PlantScavenging"
    }

    local skills = ""
    local first = true
    for i = 1, #perks do
        local perkName = perks[i]
        local perk = Perks.FromString(perkName)
        if perk then
            local level = target:getPerkLevel(perk)
            if not first then skills = skills .. "," end
            skills = skills .. '"' .. perkName .. '":' .. level
            first = false
        end
    end

    local result = '{"username":"' .. username .. '"'
    result = result .. ',"hoursSurvived":' .. string.format("%.1f", hours)
    result = result .. ',"zombieKills":' .. kills
    result = result .. ',"skills":{' .. skills .. '}'
    result = result .. '}'
    return result
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("playerstats", handlePlayerStats)
    end
end)
