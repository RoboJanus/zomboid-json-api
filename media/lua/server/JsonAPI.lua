--***********************************************************
--** JSON API - File I/O Test Build (dev only)
--** Tests write methods AND verifies readback to confirm
--** files are actually persisted to disk.
--***********************************************************

if isClient() then return end

JsonAPI = {}
JsonAPI.handlers = {}

local BASE_DIR = "json-api"
local REQUEST_DIR = BASE_DIR .. "/requests"
local RESPONSE_DIR = BASE_DIR .. "/responses"

-- ============================================================
-- Test: Try writing, then reading back to confirm persistence
-- ============================================================

local function testWriteAndRead(methodName, writeFn, readFn)
    local testContent = "test_" .. tostring(getTimestampMs())
    local writeOk, writeErr = pcall(writeFn, testContent)
    if not writeOk then
        print("[JsonAPI][TEST] " .. methodName .. " WRITE FAILED: " .. tostring(writeErr))
        return
    end

    -- Attempt to read back what we wrote
    local readOk, readResult = pcall(readFn)
    if not readOk then
        print("[JsonAPI][TEST] " .. methodName .. " WRITE OK but READ FAILED: " .. tostring(readResult))
        return
    end

    if readResult and readResult:find(testContent) then
        print("[JsonAPI][TEST] " .. methodName .. " WRITE+READ SUCCESS: content verified")
    elseif readResult then
        print("[JsonAPI][TEST] " .. methodName .. " WRITE OK, READ OK but CONTENT MISMATCH: got '" .. readResult .. "'")
    else
        print("[JsonAPI][TEST] " .. methodName .. " WRITE OK but READ returned nil/empty")
    end
end

-- ============================================================
-- Method 1: getFileWriter + getFileReader (original)
-- Path: json-api/test_method1.txt
-- ============================================================

local function testMethod1()
    testWriteAndRead("getFileWriter(json-api/...)",
        function(content)
            local w = getFileWriter(BASE_DIR .. "/test_method1.txt", true, false)
            if not w then error("writer is nil") end
            w:write(content)
            w:close()
        end,
        function()
            local r = getFileReader(BASE_DIR .. "/test_method1.txt", false)
            if not r then return nil end
            local line = r:readLine()
            r:close()
            return line
        end
    )
end

-- ============================================================
-- Method 2: getFileWriter + getFileReader (flat path)
-- Path: jsonapi_test_method2.txt
-- ============================================================

local function testMethod2()
    testWriteAndRead("getFileWriter(flat)",
        function(content)
            local w = getFileWriter("jsonapi_test_method2.txt", true, false)
            if not w then error("writer is nil") end
            w:write(content)
            w:close()
        end,
        function()
            local r = getFileReader("jsonapi_test_method2.txt", false)
            if not r then return nil end
            local line = r:readLine()
            r:close()
            return line
        end
    )
end

-- ============================================================
-- Method 3: getModFileWriter + getModFileReader
-- Path: (mod-relative) test_method3.txt
-- ============================================================

local function testMethod3()
    testWriteAndRead("getModFileWriter",
        function(content)
            local w = getModFileWriter("jsonapi", "test_method3.txt", true, false)
            if not w then error("writer is nil") end
            w:write(content)
            w:close()
        end,
        function()
            local r = getModFileReader("jsonapi", "test_method3.txt", false)
            if not r then return nil end
            local line = r:readLine()
            r:close()
            return line
        end
    )
end

-- ============================================================
-- Method 4: getFileWriter with requests/responses subdirs
-- Tests the actual queue pattern we need
-- ============================================================

local function testMethod4()
    testWriteAndRead("getFileWriter(queue pattern)",
        function(content)
            -- Write to requests dir
            local w = getFileWriter(REQUEST_DIR .. "/test_queue.json", true, false)
            if not w then error("writer is nil") end
            w:write('[{"id":"verify","content":"' .. content .. '"}]')
            w:close()
            -- Write to responses dir
            local w2 = getFileWriter(RESPONSE_DIR .. "/test_response.json", true, false)
            if not w2 then error("response writer is nil") end
            w2:write('{"verified":"' .. content .. '"}')
            w2:close()
        end,
        function()
            local r = getFileReader(RESPONSE_DIR .. "/test_response.json", false)
            if not r then return nil end
            local line = r:readLine()
            r:close()
            return line
        end
    )
end

-- ============================================================
-- Method 5: Test if getFileReader can read externally-written files
-- This tests if the klickalack-api can write and the mod can read
-- ============================================================

local function testMethod5()
    -- Try to read the queue.json that should have been written by onServerStarted
    local ok, err = pcall(function()
        local r = getFileReader(REQUEST_DIR .. "/queue.json", false)
        if not r then
            print("[JsonAPI][TEST] getFileReader(queue.json) returned nil - file doesn't exist from mod's perspective")
            return
        end
        local content = ""
        local line = r:readLine()
        while line ~= nil do
            content = content .. line
            line = r:readLine()
        end
        r:close()
        print("[JsonAPI][TEST] getFileReader(queue.json) SUCCESS - read: " .. content)
    end)
    if not ok then
        print("[JsonAPI][TEST] getFileReader(queue.json) FAILED: " .. tostring(err))
    end
end

-- ============================================================
-- Method 6: Check fileExists()
-- ============================================================

local function testMethod6()
    local ok, err = pcall(function()
        local exists1 = fileExists(BASE_DIR .. "/test_method1.txt")
        local exists2 = fileExists(REQUEST_DIR .. "/queue.json")
        local existsBogus = fileExists("this_should_not_exist_12345.txt")
        print("[JsonAPI][TEST] fileExists(test_method1.txt) = " .. tostring(exists1))
        print("[JsonAPI][TEST] fileExists(queue.json) = " .. tostring(exists2))
        print("[JsonAPI][TEST] fileExists(bogus) = " .. tostring(existsBogus))
    end)
    if not ok then
        print("[JsonAPI][TEST] fileExists test FAILED: " .. tostring(err))
    end
end

-- ============================================================
-- Run all tests
-- ============================================================

local function runAllTests()
    print("[JsonAPI][TEST] ========================================")
    print("[JsonAPI][TEST] File I/O Test Suite - 42.20 Stable")
    print("[JsonAPI][TEST] ========================================")

    testMethod1()
    testMethod2()
    testMethod3()
    testMethod4()
    testMethod5()
    testMethod6()

    print("[JsonAPI][TEST] ========================================")
    print("[JsonAPI][TEST] Tests complete.")
    print("[JsonAPI][TEST] ========================================")
end

-- ============================================================
-- JSON Helpers
-- ============================================================

function JsonAPI.jsonEscape(s)
    if not s then return "" end
    return tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"')
end

function JsonAPI.addHandler(path, handler)
    JsonAPI.handlers[path] = handler
    print("[JsonAPI] Registered handler: " .. path)
end

-- ============================================================
-- Initialization
-- ============================================================

local function onServerStarted()
    print("[JsonAPI] Server started - running I/O test suite...")
    runAllTests()
end

Events.OnServerStarted.Add(onServerStarted)
