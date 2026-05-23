# JSON API - Project Zomboid Server Mod

A server-side mod for Project Zomboid (Build 42+) that provides a file-based JSON API for external tools to interact with the game server. External tools write request files, the mod processes them and writes response files.

## How It Works

```
External Tool                    PZ Server (this mod)
     |                                  |
     |-- write queue.json ------------->|
     |                                  |-- process requests
     |                                  |-- write response files
     |<-- read responses/<id>.json -----|
```

1. External tool writes a request to `<cachedir>/Lua/json-api/requests/queue.json`
2. Mod reads the queue every N seconds (configurable), processes each request
3. Mod writes responses to `<cachedir>/Lua/json-api/responses/<id>.json`
4. External tool reads the response file

## Installation

1. Subscribe on [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3727256572)
2. Add `\jsonapi` to your server's `Mods=` line in the `.ini` file
3. Add the Workshop ID to `WorkshopItems=`
4. Restart the server

## File Locations

All files are relative to your server's Zomboid directory (the `-cachedir` path):

```
<cachedir>/Lua/json-api/
├── requests/
│   └── queue.json      ← write requests here
└── responses/
    └── <id>.json       ← read responses here
```

**Default path**: `~/Zomboid/Lua/json-api/`  
**Docker (custom cachedir)**: `<cachedir>/Lua/json-api/`

## Request Format

Write a JSON array to `requests/queue.json`:

```json
[
  {"id": "req001", "path": "sessions"},
  {"id": "req002", "path": "status"}
]
```

| Field  | Required | Description |
|--------|----------|-------------|
| `id`   | Yes      | Unique identifier. Used as the response filename (`<id>.json`) |
| `path` | Yes      | The handler endpoint to invoke |
| `args` | No       | Key-value arguments passed to the handler (reserved for future use) |

The queue is cleared after processing. Multiple requests can be batched in a single write.

## Response Format

Each request produces a response file at `responses/<id>.json` wrapped in a timestamp envelope:

```json
{
  "timestamp": 1778967526210,
  "status": "success",
  "response": {"playerCount": 1, "players": [...]}
}
```

**Error:**
```json
{
  "timestamp": 1778967526210,
  "status": "error",
  "error": "unknown path: invalid/endpoint"
}
```

## Built-in Endpoints

### `sessions`

Returns connected players with details.

```json
[{"id": "req001", "path": "sessions"}]
```

```json
{
  "playerCount": 1,
  "players": [
    {
      "username": "survivor1",
      "steamId": "76561198012345678",
      "name": "John Smith",
      "x": 10543,
      "y": 9821
    }
  ]
}
```

### `status`

Returns basic server info.

```json
[{"id": "req002", "path": "status"}]
```

```json
{
  "playerCount": 1,
  "serverName": "My Server"
}
```

### `servermsg`

Send an in-game message to all players in global chat.

```json
[{"id": "req003", "path": "servermsg", "message": "Server restarting in 5 minutes"}]
```

```json
{"sent": true, "message": "Server restarting in 5 minutes"}
```

### `save`

Trigger a world save (includes all player data).

```json
[{"id": "req004", "path": "save"}]
```

```json
{"saved": true}
```

### `additem`

Give an item to a connected player. The item appears in their inventory immediately.

```json
[{"id": "req005", "path": "additem", "username": "survivor1", "item": "Base.Axe", "count": "1"}]
```

```json
{"added": "Base.Axe", "count": 1, "to": "survivor1"}
```

### `playerstats`

Get detailed stats for a connected player including survival time, kills, and skill levels.

```json
[{"id": "req006", "path": "playerstats", "username": "survivor1"}]
```

```json
{
  "username": "survivor1",
  "name": "John Smith",
  "hoursSurvived": 48.5,
  "zombieKills": 127,
  "skills": {
    "Fitness": 3,
    "Strength": 4,
    "Sprinting": 5,
    "Lightfoot": 2,
    "Nimble": 3,
    "Sneak": 1,
    "Axe": 4,
    "Blunt": 2,
    "SmallBlunt": 1,
    "LongBlade": 0,
    "SmallBlade": 1,
    "Spear": 0,
    "Maintenance": 3,
    "Woodwork": 4,
    "Cooking": 2,
    "Farming": 1,
    "Doctor": 2,
    "Electricity": 0,
    "MetalWelding": 1,
    "Mechanics": 0,
    "Tailoring": 2,
    "Aiming": 3,
    "Reloading": 2,
    "Fishing": 0,
    "Trapping": 0,
    "PlantScavenging": 1
  }
}
```

Pass `"username": "all"` to get stats for all connected players:

```json
[{"id": "req007", "path": "playerstats", "username": "all"}]
```

```json
{
  "players": [
    {"username": "survivor1", "name": "John Smith", "hoursSurvived": 48.5, "zombieKills": 127, "skills": {...}},
    {"username": "survivor2", "name": "Jane Doe", "hoursSurvived": 12.3, "zombieKills": 42, "skills": {...}}
  ]
}
```

## Configuration

Configurable via **Sandbox Options > JSON API**:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Poll Interval | Integer (seconds) | 2 | How often to check for new requests |
| Verbose Logging | Boolean | false | Log each request/response to server console |

## Extending with Your Own Mod

Other mods can register custom API handlers by calling `JsonAPI.addHandler()`. This allows you to expose your mod's data or functionality through the same file-based API.

### Example: Adding a Custom Endpoint

Create a file in your mod at `media/lua/server/MyModAPI.lua`:

```lua
if isClient() then return end

local function handleZombieCount(args)
    local cell = getCell()
    local count = 0
    if cell then
        count = cell:getZombieList():size()
    end
    return '{"zombieCount":' .. count .. '}'
end

local function handleWeather(args)
    local cm = getClimateManager()
    local temp = cm:getAirTemperatureForCharacter()
    local raining = cm:isRaining()
    return '{"temperature":' .. temp .. ',"raining":' .. tostring(raining) .. '}'
end

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("my-mod/zombies", handleZombieCount)
        JsonAPI.addHandler("my-mod/weather", handleWeather)
    end
end)
```

Then request it:
```json
[{"id": "z001", "path": "my-mod/zombies"}]
```

Response at `responses/z001.json`:
```json
{"zombieCount": 847}
```

### Handler API

```lua
JsonAPI.addHandler(path, handlerFunction)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | string | Endpoint path (e.g., `"my-mod/endpoint"`) |
| `handlerFunction` | function | `function(args) -> string` — receives args table, must return a JSON string |

**Important notes:**

- `JsonAPI` is a global table — accessible from any mod
- Register handlers in `Events.OnServerStarted` to ensure JSON API has initialized
- Your mod should be listed **after** `jsonapi` in the server's `Mods=` line
- Handlers must return a valid JSON string
- Handlers are wrapped in `pcall` — errors are caught and returned as `{"error": "..."}`
- Avoid expensive operations in handlers since they run on the server tick

### Conventions

- Use your mod name as a prefix for paths: `"my-mod/endpoint"`
- Return valid JSON objects (not arrays or primitives at the top level)
- Keep responses concise — large responses slow down file I/O

### Mod File Structure

The built-in handlers each live in their own file under `media/lua/server/jsonapi/` as reference implementations:

```
media/lua/server/
├── JsonAPI.lua              ← Core framework (do not modify)
└── jsonapi/
    ├── sessions.lua         ← Example: read-only query
    ├── status.lua           ← Example: simple server info
    ├── servermsg.lua        ← Example: action with message arg
    ├── save.lua             ← Example: no-arg action
    ├── additem.lua          ← Example: action with multiple args
    └── playerstats.lua      ← Example: player data query with args
```

## Developing External Tools

### Writing Requests

Write the full queue atomically to avoid partial reads:

```python
import json, os

requests = [{"id": "req001", "path": "sessions"}]
queue_path = "/path/to/cachedir/Lua/json-api/requests/queue.json"

# Write atomically
tmp = queue_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(requests, f)
os.rename(tmp, queue_path)
```

### Reading Responses

Poll for the response file to appear:

```python
import json, time, os

response_path = "/path/to/cachedir/Lua/json-api/responses/req001.json"

for _ in range(50):  # 5 seconds at 100ms intervals
    if os.path.exists(response_path):
        with open(response_path) as f:
            data = json.load(f)
        os.remove(response_path)  # clean up
        break
    time.sleep(0.1)
```

### Request IDs

Use unique IDs to avoid collisions when multiple tools write concurrently. Timestamps or UUIDs work well:

```python
import time
request_id = str(int(time.time() * 1000))  # millisecond timestamp
```

## Compatibility

- Project Zomboid Build 42+ (multiplayer and singleplayer)
- Includes server and client components
- No dependencies
- Works with or without players connected

## License

MIT

## Source Code

[GitHub](https://github.com/RoboJanus/zomboid-json-api)
