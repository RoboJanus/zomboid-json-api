# JSON API - Manual Test Procedures

## Prerequisites

- Local dev server running with the mod loaded
- PZ client connected with a character
- Access to the server's `Lua/` directory to write queue files

## Writing Requests

All tests use the file-based interface:
```bash
docker exec <container> bash -c 'echo "[{\"id\":\"<test_id>\",\"path\":\"<endpoint>\", ...}]" > /project-zomboid-config/Lua/jsonapi-queue.txt'
```

Check responses at:
```bash
docker exec <container> cat /project-zomboid-config/Lua/jsonapi-resp-<test_id>.txt
```

---

## Tests (No Restart Required)

These tests can all be run in sequence without restarting the server or relogging.

### 1. Status Endpoint

1. Send: `[{"id":"t_status","path":"status"}]`
2. **Verify:** Response contains `playerCount` (>= 1) and `serverName`

### 2. Sessions Endpoint

1. Send: `[{"id":"t_sess","path":"sessions"}]`
2. **Verify:** Response contains `playerCount` >= 1
3. **Verify:** `players` array includes your username, character name, and x/y coordinates

### 3. Server Message Endpoint

1. Send: `[{"id":"t_msg","path":"servermsg","message":"Test message from JSON API"}]`
2. **Verify:** Response contains `{"sent":true}`
3. **Verify:** Message appears in the in-game chat as a server message

### 4. Targeted Server Message

1. Send: `[{"id":"t_tmsg","path":"servermsg","message":"Private test","username":"<your_username>"}]`
2. **Verify:** Response contains `{"sent":true}`
3. **Verify:** Message appears only for the targeted player

### 5. Add Item - Instant Delivery

1. Send: `[{"id":"t_add1","path":"additem","username":"<your_username>","item":"Base.Hammer","count":"1"}]`
2. **Verify:** Response contains `{"added":"Base.Hammer","count":1,"to":"<username>"}`
3. **Verify:** Hammer appears in inventory IMMEDIATELY (no relog)
4. **Verify:** Item can be equipped in hands
5. **Verify:** Item can be moved to a container

### 6. Add Item - Multiple Count

1. Send: `[{"id":"t_add2","path":"additem","username":"<your_username>","item":"Base.Nail","count":"5"}]`
2. **Verify:** Response shows count of 5
3. **Verify:** 5 nails appear in inventory immediately

### 7. Add Item - Invalid Item Type

1. Send: `[{"id":"t_add3","path":"additem","username":"<your_username>","item":"Base.FakeItem","count":"1"}]`
2. **Verify:** Response contains `{"error":"invalid item type: Base.FakeItem"}`
3. **Verify:** No crash, no item added

### 8. Add Item - Invalid Username

1. Send: `[{"id":"t_add4","path":"additem","username":"nonexistent_player","item":"Base.Axe","count":"1"}]`
2. **Verify:** Response contains `{"error":"player not found: nonexistent_player"}`

### 9. Save Endpoint

1. Send: `[{"id":"t_save","path":"save"}]`
2. **Verify:** Response contains `{"saved":true}`
3. **Verify:** Server logs show a save operation

### 10. Playerstats Endpoint

1. Send: `[{"id":"t_stats","path":"playerstats","username":"<your_username>"}]`
2. **Verify:** Response contains `username`, `name`, `hoursSurvived`, `zombieKills`, `skills`
3. **Verify:** Skills object has perk names with `level` and `xp` values

### 11. Playerstats - All Players

1. Send: `[{"id":"t_stats_all","path":"playerstats","username":"all"}]`
2. **Verify:** Response contains a `players` array
3. **Verify:** Each player entry has the same fields as single-player stats

### 12. Batch Requests

1. Send: `[{"id":"t_batch1","path":"status"},{"id":"t_batch2","path":"sessions"}]`
2. **Verify:** Both `jsonapi-resp-t_batch1.txt` and `jsonapi-resp-t_batch2.txt` are created
3. **Verify:** Each contains valid responses for their respective endpoints

### 13. Invalid Endpoint

1. Send: `[{"id":"t_invalid","path":"nonexistent/endpoint"}]`
2. **Verify:** Response contains `{"status":"error","error":"unknown path: nonexistent/endpoint"}`

---

## Tests (Relog Required)

### 14. Add Item - Persistence After Relog

1. Send: `[{"id":"t_persist","path":"additem","username":"<your_username>","item":"Base.Katana","count":"1"}]`
2. **Verify:** Katana appears immediately
3. Disconnect and reconnect to the server
4. **Verify:** Katana is still in inventory after relog
5. **Verify:** Katana is fully usable (equippable, movable)

---

## Tests (Server Restart Required)

### 15. Init Response File

1. Restart the server
2. **Verify:** `jsonapi-resp-init.txt` is created in the Lua/ directory on server start
3. **Verify:** File contains a timestamp

### 16. Sandbox Options - Poll Interval

1. Set `SandboxVars.JsonAPI.PollInterval = 10` in SandboxVars
2. Restart the server
3. Send a request
4. **Verify:** Response takes approximately 10 seconds (instead of default 2)

---

## Known Limitations

- Items delivered via additem require the inventory UI to be open/refreshed to see them (the client refresh command handles this automatically)
- The `getFileWriter` restriction in B42.20 limits all files to .txt/.cfg/.ini/.log extensions
- Queue file is cleared after processing; concurrent writers should use atomic writes
