# JSON API - Project Zomboid Server Mod

A server-side mod for Project Zomboid (Build 42+) that provides a file-based JSON API for external tools to interact with the game server. External tools write request files, the mod processes them and writes response files.

## How It Works

```
External Tool                    PZ Server (this mod)
     |                                  |
     |-- write jsonapi-queue.txt ------>|
     |                                  |-- process requests
     |                                  |-- write jsonapi-resp-<id>.txt
     |<-- read jsonapi-resp-<id>.txt ---|
```

1. External tool writes a request to `<cachedir>/Lua/jsonapi-queue.txt`
2. Mod reads the queue every N seconds (configurable), processes each request
3. Mod writes responses to `<cachedir>/Lua/jsonapi-resp-<id>.txt`
4. External tool reads the response file

> **Note (Build 42.20+):** PZ restricts `getFileWriter` to only allow `.ini`, `.cfg`, `.txt`, and `.log` extensions. All files use `.txt` despite containing JSON content.

## Installation

1. Subscribe on [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3727256572)
2. Add `\jsonapi` to your server's `Mods=` line in the `.ini` file
3. Add the Workshop ID to `WorkshopItems=`
4. Restart the server

## File Locations

All files are in the `Lua/` directory under your server's Zomboid cache directory (the `-cachedir` path):

```
<cachedir>/Lua/
├── jsonapi-queue.txt          ← write requests here
├── jsonapi-resp-<id>.txt      ← read responses here
└── jsonapi-resp-init.txt      ← written on server start (ready marker)
```

**Default path**: `~/Zomboid/Lua/`  
**Docker (custom cachedir)**: `<cachedir>/Lua/`

## Request Format

Write a JSON array to `jsonapi-queue.txt`:

```json
[
  {"id": "req001", "path": "sessions"},
  {"id": "req002", "path": "status"}
]
```

| Field  | Required | Description |
|--------|----------|-------------|
| `id`   | Yes      | Unique identifier. Used as the response filename (`jsonapi-resp-<id>.txt`) |
| `path` | Yes      | The handler endpoint to invoke |
| `args` | No       | Key-value arguments passed to the handler |

The queue is cleared after processing. Multiple requests can be batched in a single write.

## Response Format

Each request produces a response file at `jsonapi-resp-<id>.txt` wrapped in a timestamp envelope:

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
    ...
  }
}
```

Pass `"username": "all"` to get stats for all connected players.

## Configuration

Configurable via **Sandbox Options > JSON API**:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Poll Interval | Integer (seconds) | 2 | How often to check for new requests |
| Verbose Logging | Boolean | false | Log each request/response to server console |

## Extending with Your Own Mod

Other mods can register custom API handlers by calling `JsonAPI.addHandler()`:

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

Events.OnServerStarted.Add(function()
    if JsonAPI then
        JsonAPI.addHandler("my-mod/zombies", handleZombieCount)
    end
end)
```

Request: `[{"id": "z001", "path": "my-mod/zombies"}]`  
Response at `jsonapi-resp-z001.txt`: `{"zombieCount": 847}`

## Developing External Tools

### Writing Requests

Write the full queue atomically to avoid partial reads:

```python
import json, os

requests = [{"id": "req001", "path": "sessions"}]
queue_path = "/path/to/cachedir/Lua/jsonapi-queue.txt"

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

response_path = "/path/to/cachedir/Lua/jsonapi-resp-req001.txt"

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

## Build 42.20 Compatibility Notes

PZ 42.20 introduced a security restriction that limits `getFileWriter` to files with extensions `.ini`, `.cfg`, `.txt`, or `.log` only. This mod uses `.txt` for all files. The file content is still JSON — just with a `.txt` extension.

Additionally, `getFileWriter` cannot create files in nested subdirectories that don't already exist. All files are written flat in the `Lua/` directory with a `jsonapi-` prefix.

## Compatibility

- Project Zomboid Build 42.20+ (multiplayer dedicated servers)
- Includes server and client components
- No dependencies
- Works with or without players connected

## License

MIT

## Source Code

[GitHub](https://github.com/RoboJanus/zomboid-json-api)
