#!/usr/bin/env python3
"""Test JSON API mod endpoints against a running PZ server container."""
import json
import sys
import time

import docker

API_DIR = "/project-zomboid-config/Lua/json-api"


def send_request(container, req):
    req_id = f"test_{int(time.time()*1000)}"
    req["id"] = req_id
    payload = json.dumps([req])
    container.exec_run(["sh", "-c", f"echo '{payload}' > {API_DIR}/requests/queue.json"])
    for _ in range(10):
        time.sleep(1)
        result = container.exec_run(f"cat {API_DIR}/responses/{req_id}.json")
        if result.exit_code == 0 and result.output.strip():
            return json.loads(result.output.decode())
    return None


def check(label, response, expected_keys):
    if not response:
        print(f"  ✗ No response received")
        return False
    if response.get("status") != "success":
        print(f"  ✗ Status: {response.get('status')} - {response.get('error', '')}")
        return False
    data = response.get("response", {})
    missing = [k for k in expected_keys if k not in data]
    if missing:
        print(f"  ✗ Missing keys: {missing}")
        return False
    print(f"  ✓ {label} passed")
    print(f"    {json.dumps(data, indent=2)[:500]}")
    return True


def confirm(prompt):
    answer = input(f"\n{prompt} [Y/n]: ").strip().lower()
    return answer != "n"


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <container-name>")
        sys.exit(1)

    server = sys.argv[1]
    c = docker.DockerClient(base_url="tcp://192.168.50.252:2375")
    try:
        container = c.containers.get(server)
    except docker.errors.NotFound:
        print(f"Container '{server}' not found")
        sys.exit(1)

    print(f"\n=== JSON API Test Suite: {server} ===\n")

    # 1. Sessions
    print("[1/5] sessions")
    resp = send_request(container, {"path": "sessions"})
    check("sessions", resp, ["playerCount", "players"])
    if not resp or not resp.get("response", {}).get("players"):
        print("  ⚠ No players connected. additem/playerstats tests will fail.")
        if not confirm("Continue?"):
            sys.exit(0)
    else:
        username = resp["response"]["players"][0]["username"]
        print(f"  Using player: {username}")

    if not confirm("Proceed to status?"):
        sys.exit(0)

    # 2. Status
    print("[2/5] status")
    resp = send_request(container, {"path": "status"})
    check("status", resp, ["playerCount", "serverName"])

    if not confirm("Proceed to servermsg?"):
        sys.exit(0)

    # 3. Servermsg
    print("[3/5] servermsg")
    resp = send_request(container, {"path": "servermsg", "message": "JSON API test message"})
    check("servermsg", resp, ["sent", "message"])
    if not confirm("Did you see the message in-game?"):
        print("  ✗ servermsg not visible")

    # 4. Additem
    print("[4/5] additem")
    resp = send_request(container, {"path": "additem", "username": username, "item": "Base.Axe", "count": "1"})
    if check("additem", resp, ["added", "count", "to"]):
        data = resp["response"]
        assert data["added"] == "Base.Axe" and data["count"] == 1 and data["to"] == username
    if not confirm("Did the item appear in inventory?"):
        print("  ✗ additem not visible")

    # 5. Playerstats
    print("[5/5] playerstats")
    resp = send_request(container, {"path": "playerstats", "username": username})
    check("playerstats", resp, ["username", "hoursSurvived", "zombieKills", "skills"])

    print("\n=== All tests complete ===")


if __name__ == "__main__":
    main()
