if isClient() then return end

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

    -- Dynamically discover all perks from the Perks registry
    local skills = ""
    local first = true
    local perkList = PerkFactory.PerkList
    if perkList then
        for i = 0, perkList:size() - 1 do
            local perk = perkList:get(i)
            if perk then
                local perkType = perk:getType()
                if perkType and perkType ~= "None" then
                    local level = player:getPerkLevel(perk)
                    local xp = player:getXp():getXP(perk)
                    if not first then skills = skills .. "," end
                    skills = skills .. '"' .. perkType .. '":{"level":' .. level .. ',"xp":' .. string.format("%.1f", xp) .. '}'
                    first = false
                end
            end
        end
    end

    return '{"username":"' .. JsonAPI.jsonEscape(username) .. '"'
        .. ',"name":"' .. JsonAPI.jsonEscape(name or username) .. '"'
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
