--***********************************************************
--** JSON API - Core Framework (42.20 File I/O Test Build)
--** Testing multiple file write approaches to find what works.
--***********************************************************

if isClient() then return end

JsonAPI = {}
JsonAPI.handlers = {}

local MOD_ID = "jsonapi"
local REQUEST_DIR = "requests"
local RESPONSE_DIR = "responses"

-- ============================================================
-- Test Results Tracking
-- ============================================================

local testResults = {}

local function logTest(method, success, detail)
    local status = success and "SUCCESS" or "FAILED"
    print("[JsonAPI][TEST] " .. method .. ": " .. status .. " - " .. (detail or ""))
    testResults[method] = {success = success, detail = detail or ""}
end

-- ============================================================
-- Method 1: getModFileWriter (current approach)
-- ============================================================

local function tryModFileWriter()
    local ok, err = pcall(function()
        local writer = getModFileWriter(MOD_ID, "test_modfilewriter.txt", true, false)
        if writer then
            writer:write("modfilewriter_works")
            writer:close()
            logTest("getModFileWriter", true, "wrote to test_modfilewriter.txt")
        else
            logTest("getModFileWriter", false, "returned nil")
        end
    end)
    if not ok then
        logTest("getModFileWriter", false, tostring(err))
    end
end

-- ============================================================
-- Method 2: getSandboxFileWriter
-- ============================================================

local function trySandboxFileWriter()
    local ok, err = pcall(function()
        local writer = getSandboxFileWriter("jsonapi_test_sandbox.txt", true, false)
        if writer then
            writer:write("sandboxfilewriter_works")
            writer:close()
            logTest("getSandboxFileWriter", true, "wrote to jsonapi_test_sandbox.txt")
        else
            logTest("getSandboxFileWriter", false, "returned nil")
        end
    end)
    if not ok then
        logTest("getSandboxFileWriter", false, tostring(err))
    end
end

-- ============================================================
-- Method 3: getFileWriter (original approach, may be restricted)
-- ============================================================

local function tryFileWriter()
    local ok, err = pcall(function()
        local writer = getFileWriter("jsonapi_test_filewriter.txt", true, false)
        if writer then
            writer:write("filewriter_works")
            writer:close()
            logTest("getFileWriter", true, "wrote to jsonapi_test_filewriter.txt")
        else
            logTest("getFileWriter", false, "returned nil")
        end
    end)
    if not ok then
        logTest("getFileWriter", false, tostring(err))
    end
end

-- ============================================================
-- Method 4: getFileWriter with absolute-style path
-- ============================================================

local function tryFileWriterLuaPath()
    local ok, err = pcall(function()
        local writer = getFileWriter("Lua/jsonapi/test_luapath.txt", true, false)
        if writer then
            writer:write("filewriter_luapath_works")
            writer:close()
            logTest("getFileWriter(Lua/path)", true, "wrote to Lua/jsonapi/test_luapath.txt")
        else
            logTest("getFileWriter(Lua/path)", false, "returned nil")
        end
    end)
    if not ok then
        logTest("getFileWriter(Lua/path)", false, tostring(err))
    end
end

-- ============================================================
-- Method 5: getModFileWriter with subdirectory
-- ============================================================

local function tryModFileWriterSubdir()
    local ok, err = pcall(function()
        local writer = getModFileWriter(MOD_ID, "responses/test_subdir.txt", true, false)
        if writer then
            writer:write("modfilewriter_subdir_works")
            writer:close()
            logTest("getModFileWriter(subdir)", true, "wrote to responses/test_subdir.txt")
        else
            logTest("getModFileWriter(subdir)", false, "returned nil")
        end
    end)
    if not ok then
        logTest("getModFileWriter(subdir)", false, tostring(err))
    end
end

-- ============================================================
-- Method 6: getFileOutput (DataOutputStream - different API)
-- ============================================================

local function tryFileOutput()
    local ok, err = pcall(function()
        local stream = getFileOutput("jsonapi_test_fileoutput.txt")
        if stream then
            -- getFileOutput returns a DataOutputStream
            stream:writeUTF("fileoutput_works")
            stream:close()
            logTest("getFileOutput", true, "wrote to jsonapi_test_fileoutput.txt")
        else
            logTest("getFileOutput", false, "returned nil")
        end
    end)
    if not ok then
        logTest("getFileOutput", false, tostring(err))
    end
end

-- ============================================================
-- Run all tests on server start
-- ============================================================

local function runFileWriteTests()
    print("[JsonAPI][TEST] ========================================")
    print("[JsonAPI][TEST] Starting file write method tests for 42.20")
    print("[JsonAPI][TEST] ========================================")

    tryModFileWriter()
    trySandboxFileWriter()
    tryFileWriter()
    tryFileWriterLuaPath()
    tryModFileWriterSubdir()
    tryFileOutput()

    print("[JsonAPI][TEST] ========================================")
    print("[JsonAPI][TEST] Test summary:")
    for method, result in pairs(testResults) do
        local status = result.success and "OK" or "FAIL"
        print("[JsonAPI][TEST]   " .. status .. " | " .. method .. " | " .. result.detail)
    end
    print("[JsonAPI][TEST] ========================================")
end

-- ============================================================
-- JSON Helpers (exposed for handler use)
-- ============================================================

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
-- Initialization
-- ============================================================

local function onServerStarted()
    print("[JsonAPI] Server started, running file I/O tests...")
    runFileWriteTests()
end

Events.OnServerStarted.Add(onServerStarted)
