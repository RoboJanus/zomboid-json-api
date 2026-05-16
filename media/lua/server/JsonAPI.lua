--***********************************************************
--** JSON API
--** File-based request/response API for Project Zomboid servers.
--** External tools write request JSON files, the mod processes
--** them and writes response JSON files.
--**
--** Directory structure (in <cachedir>/Lua/json-api/):
--**   requests/   - incoming request files (consumed on processing)
--**   responses/  - output response files
--**
--** Request format: [{"path":"endpoint/name","args":{}}]
--** Response: written to responses/<request-filename>
--**
--** Extensible: other mods can register handlers via
--**   JsonAPI.addHandler("path/name", function(args) return responseString end)
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

local function readFile(path)
    local reader = getFileReader(path, true)
    if not reader then return nil end
    local content = ""
    local line = reader:readLine()
    while line ~= nil do
        content = content .. line
        line = reader:readLine()
    end
    reader:close()
    return content
end

local function deleteFile(path)
    local f = getFileWriter(path, true, false)
    if f then
        f:write("")
        f:close()
    end
end

-- ============================================================
-- JSON Helpers
-- ============================================================

local function steamIdToString(steamId)
    return Long.toString(steamId)
end

local function jsonEscape(s)
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
-- Built-in Handlers
-- ============================================================

local function handleSessions(args)
    local onlinePlayers = getOnlinePlayers()
    if not onlinePlayers then return '{"playerCount":0,"players":[]}' end
    local count = onlinePlayers:size()
    local playersJson = ""
    for i = 0, count - 1 do
        local p = onlinePlayers:get(i)
        local username = p:getUsername()
        local steamId = steamIdToString(p:getSteamID())
        local name = username
        local desc = p:getDescriptor()
        if desc then
            local fn = desc:getForename() or ""
            local sn = desc:getSurname() or ""
            if fn ~= "" or sn ~= "" then name = fn .. " " .. sn end
        end
        if i > 0 then playersJson = playersJson .. "," end
        playersJson = playersJson .. '{"username":"' .. jsonEscape(username) .. '","steamId":"' .. steamId .. '","name":"' .. jsonEscape(name) .. '","x":' .. math.floor(p:getX()) .. ',"y":' .. math.floor(p:getY()) .. '}'
    end
    return '{"playerCount":' .. count .. ',"players":[' .. playersJson .. ']}'
end

local function handleStatus(args)
    local onlinePlayers = getOnlinePlayers()
    local count = 0
    if onlinePlayers then count = onlinePlayers:size() end
    return '{"playerCount":' .. count .. ',"serverName":"' .. jsonEscape(getServerName()) .. '"}'
end

local function handleKick(args)
    local username = args.username
    if not username then return '{"error":"missing arg: username"}' end
    local reason = args.reason or "Kicked by admin"
    local onlinePlayers = getOnlinePlayers()
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            if p:getUsername() == username then
                p:setKicked(reason)
                return '{"kicked":"' .. jsonEscape(username) .. '","reason":"' .. jsonEscape(reason) .. '"}'
            end
        end
    end
    return '{"error":"player not found: ' .. jsonEscape(username) .. '"}'
end

local function handleServerMsg(args)
    local message = args.message
    if not message then return '{"error":"missing arg: message"}' end
    getGameServer():sendServerCommand("servermsg", message)
    return '{"sent":true,"message":"' .. jsonEscape(message) .. '"}'
end

local function handleSave(args)
    getGameServer():save()
    return '{"saved":true}'
end

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
                local inv = p:getInventory()
                for c = 1, count do
                    inv:AddItem(itemType)
                end
                return '{"added":"' .. jsonEscape(itemType) .. '","count":' .. count .. ',"to":"' .. jsonEscape(username) .. '"}'
            end
        end
    end
    return '{"error":"player not found: ' .. jsonEscape(username) .. '"}'
end

local function handleKickShutdown(args)
    local reason = args.reason or "Safe Server Shutdown Initiated"
    local onlinePlayers = getOnlinePlayers()
    local kicked = 0
    if onlinePlayers then
        for i = 0, onlinePlayers:size() - 1 do
            local p = onlinePlayers:get(i)
            p:setKicked(reason)
            kicked = kicked + 1
        end
    end
    getGameServer():save()
    getGameServer():shutdown()
    return '{"kicked":' .. kicked .. ',"reason":"' .. jsonEscape(reason) .. '","shutdown":true}'
end

-- ============================================================
-- Request Processing
-- ============================================================

local function checkRequests()
    -- Read the request queue file (JSON array of request objects)
    -- Format: [{"id":"test001","path":"sessions","args":{}}]
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

    -- Parse requests (simple pattern matching for each object)
    for id, path in content:gmatch('"id"%s*:%s*"([^"]*)"%s*,%s*"path"%s*:%s*"([^"]*)"') do
        local handler = JsonAPI.handlers[path]
        if handler then
            -- Extract args: find all "key":"value" pairs that aren't id or path
            local args = {}
            for key, value in content:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
                if key ~= "id" and key ~= "path" then
                    args[key] = value
                end
            end
            local ok, response = pcall(handler, args)
            local ts = string.format("%.0f", getTimestampMs())
            if ok then
                writeFile(RESPONSE_DIR .. "/" .. id .. ".json", '{"timestamp":' .. ts .. ',"response":' .. response .. '}')
                if SandboxVars and SandboxVars.JsonAPI and SandboxVars.JsonAPI.VerboseLogging then
                    print("[JsonAPI] Request: " .. id .. " -> " .. path)
                    print("[JsonAPI] Response: " .. RESPONSE_DIR .. "/" .. id .. ".json")
                end
            else
                writeFile(RESPONSE_DIR .. "/" .. id .. ".json", '{"timestamp":' .. ts .. ',"error":"' .. jsonEscape(tostring(response)) .. '"}')
                print("[JsonAPI] ERROR processing " .. id .. ": " .. tostring(response))
            end
        else
            local ts = string.format("%.0f", getTimestampMs())
            writeFile(RESPONSE_DIR .. "/" .. id .. ".json", '{"timestamp":' .. ts .. ',"error":"unknown path: ' .. jsonEscape(path) .. '"}')
            if SandboxVars and SandboxVars.JsonAPI and SandboxVars.JsonAPI.VerboseLogging then
                print("[JsonAPI] Request: " .. id .. " -> " .. path .. " (unknown)")
            end
        end
    end
end

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
    -- Ensure directories and queue file exist
    writeFile(REQUEST_DIR .. "/queue.json", "[]")
    writeFile(RESPONSE_DIR .. "/.init", "")

    -- Register built-in handlers
    JsonAPI.addHandler("sessions", handleSessions)
    JsonAPI.addHandler("status", handleStatus)
    JsonAPI.addHandler("kick", handleKick)
    JsonAPI.addHandler("servermsg", handleServerMsg)
    JsonAPI.addHandler("save", handleSave)
    JsonAPI.addHandler("additem", handleAddItem)
    JsonAPI.addHandler("kickShutdown", handleKickShutdown)

    print("[JsonAPI] Initialized. Listening for requests in Lua/" .. REQUEST_DIR .. "/queue.json")
end

Events.OnServerStarted.Add(onServerStarted)
Events.OnTickEvenPaused.Add(onTick)
