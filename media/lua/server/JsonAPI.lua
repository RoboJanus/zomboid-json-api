if isClient() then return end

local JsonAPI = {}
JsonAPI.tracked = {}
local OUTPUT_DIR = "json-api"

local function writeFile(filename, content, append)
    local writer = getFileWriter(OUTPUT_DIR .. "/" .. filename, true, append or false)
    if writer then
        writer:write(content)
        writer:close()
    end
end

local function buildPlayerJson(p)
    local username = p:getUsername()
    local steamId = tostring(p:getSteamID())
    local x = math.floor(p:getX())
    local y = math.floor(p:getY())
    return '{"username":"' .. username .. '","steamId":"' .. steamId .. '","x":' .. x .. ',"y":' .. y .. '}'
end

local function buildStatusJson()
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return '{"playerCount":0,"players":[]}' end
    local count = onlinePlayers:size()
    local playersJson = ""
    for i = 0, count - 1 do
        if i > 0 then playersJson = playersJson .. "," end
        playersJson = playersJson .. buildPlayerJson(onlinePlayers:get(i))
    end
    return '{"playerCount":' .. count .. ',"players":[' .. playersJson .. ']}'
end

local function buildEventJson(eventType, username, steamId)
    return '{"type":"' .. eventType .. '","username":"' .. username .. '","steamId":"' .. steamId .. '"}'
end

local function checkPlayers()
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return end
    local currentUsers = {}
    for i = 0, onlinePlayers:size() - 1 do
        local p = onlinePlayers:get(i)
        local username = p:getUsername()
        local steamId = tostring(p:getSteamID())
        currentUsers[username] = steamId
        if not JsonAPI.tracked[username] then
            JsonAPI.tracked[username] = steamId
            writeFile("events.jsonl", buildEventJson("connect", username, steamId) .. "\n", true)
            print("[JsonAPI] Connected: " .. username)
        end
    end
    for username, steamId in pairs(JsonAPI.tracked) do
        if not currentUsers[username] then
            writeFile("events.jsonl", buildEventJson("disconnect", username, steamId) .. "\n", true)
            print("[JsonAPI] Disconnected: " .. username)
            JsonAPI.tracked[username] = nil
        end
    end
    writeFile("status.json", buildStatusJson(), false)
end

local function onServerStarted()
    writeFile("events.jsonl", "", false)
    writeFile("status.json", '{"playerCount":0,"players":[]}', false)
    print("[JsonAPI] Initialized. Output: Lua/" .. OUTPUT_DIR .. "/")
end

Events.OnServerStarted.Add(onServerStarted)
Events.EveryOneMinute.Add(checkPlayers)
