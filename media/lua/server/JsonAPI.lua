--***********************************************************
--** JSON API - Core Framework
--** File-based request/response API for Project Zomboid servers.
--** External tools write request JSON files, the mod processes
--** them and writes response JSON files.
--**
--** Directory structure (in <cachedir>/Lua/json-api/):
--**   requests/   - incoming request files (consumed on processing)
--**   responses/  - output response files
--**
--** Request format: [{"id":"reqId","path":"endpoint","args":{}}]
--** Response: written to responses/<id>.json
--**
--** Extensible: other mods can register handlers via
--**   JsonAPI.addHandler("path/name", function(args) return jsonString end)
--***********************************************************

if isClient() then return end

JsonAPI = {}
JsonAPI.handlers = {}

local BASE_DIR = "json-api"
local REQUEST_DIR = BASE_DIR .. "/requests"
local RESPONSE_DIR = BASE_DIR .. "/responses"

-- ============================================================
-- File I/O
-- ============================================================

local function writeFile(path, content)
    local writer = getFileWriter(path, true, false)
    if writer then
        writer:write(content)
        writer:close()
    end
end

-- ============================================================
-- JSON Helpers (exposed for handler use)
-- ============================================================

function JsonAPI.steamIdToString(player)
    -- Pass the player object, call getSteamID() and toString() in one Java chain
    return Long.toString(player:getSteamID())
end

function JsonAPI.jsonEscape(s)
    if not s then return "" end
    return tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"')
end

-- ============================================================
-- Handler Registration
-- ============================================================

function JsonAPI.addHandler(path, handler)
    JsonAPI.handlers[path] = handler
    print("[JsonAPI] Registered handler: " .. path)
end

-- ============================================================
-- Request Processing
-- ============================================================

local function checkRequests()
    local reader = getFileReader(REQUEST_DIR .. "/queue.json", true)
    if not reader then return end
    local content = ""
    local line = reader:readLine()
    while line ~= nil do
        content = content .. line
        line = reader:readLine()
    end
    reader:close()

    if content == "" or content == "[]" then return end

    -- Clear the queue
    writeFile(REQUEST_DIR .. "/queue.json", "[]")

    -- Parse and process each request
    for id, path in content:gmatch('"id"%s*:%s*"([^"]*)"%s*,%s*"path"%s*:%s*"([^"]*)"') do
        local handler = JsonAPI.handlers[path]
        if handler then
            local args = {}
            for key, value in content:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
                if key ~= "id" and key ~= "path" then
                    args[key] = value
                end
            end
            local ok, response = pcall(handler, args)
            local ts = string.format("%.0f", getTimestampMs())
            if ok then
                writeFile(RESPONSE_DIR .. "/" .. id .. ".json", '{"timestamp":' .. ts .. ',"status":"success","response":' .. response .. '}')
                if SandboxVars and SandboxVars.JsonAPI and SandboxVars.JsonAPI.VerboseLogging then
                    print("[JsonAPI] Request: " .. id .. " -> " .. path)
                    print("[JsonAPI] Response: " .. RESPONSE_DIR .. "/" .. id .. ".json")
                end
            else
                writeFile(RESPONSE_DIR .. "/" .. id .. ".json", '{"timestamp":' .. ts .. ',"status":"error","error":"' .. JsonAPI.jsonEscape(tostring(response)) .. '"}')
                print("[JsonAPI] ERROR processing " .. id .. ": " .. tostring(response))
            end
        else
            local ts = string.format("%.0f", getTimestampMs())
            writeFile(RESPONSE_DIR .. "/" .. id .. ".json", '{"timestamp":' .. ts .. ',"status":"error","error":"unknown path: ' .. JsonAPI.jsonEscape(path) .. '"}')
            if SandboxVars and SandboxVars.JsonAPI and SandboxVars.JsonAPI.VerboseLogging then
                print("[JsonAPI] Request: " .. id .. " -> " .. path .. " (unknown)")
            end
        end
    end
end

-- ============================================================
-- Tick
-- ============================================================

local POLL_INTERVAL_MS = 2000
local lastPollTime = 0

local function onTick()
    local now = getTimestampMs()
    local interval = POLL_INTERVAL_MS
    if SandboxVars and SandboxVars.JsonAPI and SandboxVars.JsonAPI.PollInterval then
        interval = SandboxVars.JsonAPI.PollInterval * 1000
    end
    if now - lastPollTime < interval then return end
    lastPollTime = now
    checkRequests()
end

-- ============================================================
-- Initialization
-- ============================================================

local function onServerStarted()
    writeFile(REQUEST_DIR .. "/queue.json", "[]")
    writeFile(RESPONSE_DIR .. "/.init", "")
    print("[JsonAPI] Initialized. Listening for requests in Lua/" .. REQUEST_DIR .. "/queue.json")
end

Events.OnServerStarted.Add(onServerStarted)
Events.OnTickEvenPaused.Add(onTick)
