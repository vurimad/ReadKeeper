#!/usr/bin/env bash
# Prints the UDID of the best available iPhone simulator (newest iOS, prefers a "Pro" model).
set -euo pipefail

xcrun simctl list devices available -j | python3 -c '
import json, re, sys

devices = json.load(sys.stdin)["devices"]
candidates = []
for runtime, items in devices.items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = (int(match.group(1)), int(match.group(2)))
    for device in items:
        name = device["name"]
        if not name.startswith("iPhone"):
            continue
        preferred = 1 if ("Pro" in name and "Max" not in name) else 0
        candidates.append((version, preferred, name, device["udid"]))

if not candidates:
    sys.exit("No iPhone simulator found")

version, _, name, udid = max(candidates)
print(f"Using {name} (iOS {version[0]}.{version[1]})", file=sys.stderr)
print(udid)
'
