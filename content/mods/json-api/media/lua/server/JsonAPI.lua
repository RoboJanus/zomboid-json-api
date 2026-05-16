--***********************************************************
--** JSON API
--** Tracks player sessions via polling and writes JSON files
--** for external consumption by server management tools.
--**
--** Output files (in Zomboid/Lua/json-api/):
--**   status.json  - current server state and player list
--**   events.jsonl - append-only log of connect/disconnect events
--***********************************************************

if isClient() then return end

local JsonAPI = {}

-- Tracked players: username -> {steamId, connectTime}
JsonAPI.tracked = {}

-- ============================================================
-- JSON Serialization
-- ============================================================

local function jsonEscape(s)
    return s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
end

local function toJson(val)
    if val == nil then return "null" end
    local t = type(val)
    if t == "string" then return '"' .. jsonEscape(val) .. '"' end
    if t == "number" then return tostring(val) end
    if t == "boolean" then return val and "true" or "false" end
    if t ~= "table" then return '"' .. tostring(val) .. '"' end
    -- Array check: sequential integer keys starting at 1
    if #val > 0 or next(val) == nil then
        local parts = {}
        for _, v in ipairs(val) do parts[#parts+1] = toJson(v) end
        return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for k, v in pairs(val) do
        parts[#parts+1] = '"' .. tostring(k) .. '":' .. toJson(v)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

-- ============================================================
-- File I/O
-- ============================================================

local OUTPUT_DIR = "json-api"

local function writeFile(filename, content, append)
    local writer = getFileWriter(OUTPUT_DIR .. "/" .. filename, true, append or false)
    if writer then
        writer:write(content)
        writer:close()
    end
end

local function appendEvent(event)
    writeFile("events.jsonl", toJson(event) .. "\n", true)
end

-- ============================================================
-- Session Tracking (poll-based)
-- ============================================================

local function getTimestamp()
    return Calendar.getInstance():getTimeInMillis()
end

local function checkPlayers()
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return end

    local currentUsers = {}
    local playerData = {}

    for i = 0, onlinePlayers:size() - 1 do
        local p = onlinePlayers:get(i)
        local username = p:getUsername()
        local steamId = tostring(p:getSteamID())
        currentUsers[username] = steamId

        -- Detect new connection
        if not JsonAPI.tracked[username] then
            local ts = getTimestamp()
            JsonAPI.tracked[username] = { steamId = steamId, connectTime = ts }
            local event = { type = "connect", username = username, steamId = steamId, timestamp = ts }
            appendEvent(event)
            print("[JsonAPI] Connected: " .. username .. " (" .. steamId .. ")")
        end

        local session = JsonAPI.tracked[username]
        playerData[#playerData+1] = {
            username = username,
            steamId = steamId,
            x = math.floor(p:getX()),
            y = math.floor(p:getY()),
            connectTime = session.connectTime
        }
    end

    -- Detect disconnections
    for username, session in pairs(JsonAPI.tracked) do
        if not currentUsers[username] then
            local ts = getTimestamp()
            local event = {
                type = "disconnect",
                username = username,
                steamId = session.steamId,
                timestamp = ts,
                duration = ts - session.connectTime
            }
            appendEvent(event)
            print("[JsonAPI] Disconnected: " .. username .. " (" .. session.steamId .. ")")
            JsonAPI.tracked[username] = nil
        end
    end

    -- Write status file
    local status = {
        playerCount = #playerData,
        players = playerData,
        timestamp = getTimestamp()
    }
    writeFile("status.json", toJson(status), false)
end

-- ============================================================
-- Initialization & Event Hooks
-- ============================================================

local function onServerStarted()
    -- Clear stale events on server start
    writeFile("events.jsonl", "", false)
    writeFile("status.json", toJson({ playerCount = 0, players = {}, timestamp = getTimestamp() }), false)
    print("[JsonAPI] Initialized. Output: Lua/" .. OUTPUT_DIR .. "/")
end

Events.OnServerStarted.Add(onServerStarted)
Events.EveryOneMinute.Add(checkPlayers)
