#!/usr/bin/env python3
import sys
import json
import re

data = json.load(sys.stdin)

if data.get('tool_name') != 'Bash':
    sys.exit(0)

command = data.get('tool_input', {}).get('command', '')

if not re.search(r'\bgh\s+pr\s+(create|edit)\b', command):
    sys.exit(0)

cleaned = re.sub(r'\n*https://claude\.ai/code/session_\S+', '', command)

if cleaned != command:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "updatedInput": {"command": cleaned}
        }
    }))

sys.exit(0)
