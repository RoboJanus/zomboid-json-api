# JSON API - Project Zomboid Server Mod

A server-side mod for Project Zomboid (Build 42+) that writes real-time JSON status and player session events to files, enabling external tools to monitor and manage game servers without RCON parsing.

## Output Files

Written to `<Zomboid cachedir>/Lua/json-api/`:

### `status.json`

Overwritten every game minute (~2 seconds real time). Contains current server state:

```json
{
  "playerCount": 2,
  "players": [
    {"username": "player1", "steamId": "76561198012345678", "x": 1234, "y": 5678, "connectTime": 1778892000000},
    {"username": "player2", "steamId": "76561198087654321", "x": 2345, "y": 6789, "connectTime": 1778892500000}
  ],
  "timestamp": 1778892060000
}
```

### `events.jsonl`

Append-only log of connect/disconnect events (cleared on server start):

```json
{"type":"connect","username":"player1","steamId":"76561198012345678","timestamp":1778892000000}
{"type":"disconnect","username":"player1","steamId":"76561198012345678","timestamp":1778893000000,"duration":1000000}
```

## Installation

1. Subscribe to the mod on Steam Workshop
2. Add `json-api` to your server's `Mods=` line in the `.ini` file
3. Restart the server

## File Location

The output directory depends on your server's `-cachedir` setting:

- **Default**: `~/Zomboid/Lua/json-api/`
- **Docker (custom cachedir)**: `<cachedir>/Lua/json-api/`

## Use Cases

- External dashboards showing live server status
- Discord bots announcing player connections
- Session tracking and playtime analytics
- Server management APIs that avoid fragile RCON text parsing

## Compatibility

- Project Zomboid Build 42+ (multiplayer)
- Server-side only — no client installation required

## License

MIT
