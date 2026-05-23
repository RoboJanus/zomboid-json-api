if isClient() then return end

local perks = {
    "Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble",
    "Sneak", "Axe", "Blunt", "SmallBlunt", "LongBlade",
    "SmallBlade", "Spear", "Maintenance", "Woodwork",
    "Cooking", "Farming", "Doctor", "Electricity",
    "MetalWelding", "Mechanics", "Tailoring", "Aiming",
    "Reloading", "Fishing", "Trapping", "PlantScavenging"
}

local function buildPlayerStats(player)
    local username = player:getUsername()
    local name = username
    local desc = player:getDescriptor()
    if desc then
        local fn = desc:getForename() or ""
        local sn = desc:getSurname() or ""
        if fn ~= "" or sn ~= "" then name = fn .. " " .. sn end
    end
    local hours = player:getHoursSurvived()
    local kills = player:getZombieKills()

    local skills = ""
    local first = true
    for i = 1, #perks do
        local perkName = perks[i]
        local perk = Perks.FromString(perkName)
        if perk then
            local level = player:getPerkLevel(perk)
            if not first then skills = skills .. "," end
            skills = skills .. '"' .. perkName .. '":' .. level
            first = false
        end
    end

    return '{"username":"' .. username .. '"'
        .. ',"name":"' .. (name or username) .. '"'
        .. ',"hoursSurvived":' .. string.format("%.1f", hours)
        .. ',"zombieKills":' .. kills
        .. ',"skills":{' .. skills .. '}}'
end

local function handlePlayerStats(args)
    local username = args and args.username
    if not username then
        return '{"error":"username required"}'
    end

    local players = getOnlinePlayers()

    if username == "all" then
        local results = ""
        local first = true
        for i = 0, players:size() - 1 do
            if not first then results = results .. "," end
            results = results .. buildPlayerStats(players:get(i))
            first = false
        end
        return '{"players":[' .. results .. ']}'
    end

    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p:getUsername() == username then
            return buildPlayerStats(p)
        end
    end

    return '{"error":"player not found"}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("playerstats", handlePlayerStats)
    end
end)
