#!/usr/bin/env python3
"""
Syncs ~/.pi/agent/models.json's contextWindow/maxTokens to match whichever server config
dev.sh/dev-reasoning.sh is about to start — run automatically on every launch so these two
files can't drift out of sync silently (they did, twice, on 2026-08-16/17: models.json kept
whatever a prior manual test had left it at, and a later plain `localai` run picked up a
mismatched value with no warning). See memory/decisions.md.

Usage: ./scripts/set-model-profile.py <coder|reasoning|auto>

"auto" queries the running server's /props for which GGUF is actually loaded and picks the
matching profile — use this from dev.sh, which may find an already-running server left over
from a different profile (e.g. someone left the reasoning server up, then ran plain `localai`
for a quick coding task elsewhere). Explicit "coder"/"reasoning" force that profile regardless
of what's running — use this right after starting a server with that exact config, so the
profile is correct even before /props is queryable.
"""
import json
import sys
import urllib.request
from pathlib import Path

PROFILES = {
    "coder": {"name": "qwopus3.6:35b (local)", "contextWindow": 65536, "maxTokens": 32768,
               "match": "Qwopus3.6"},
    "reasoning": {"name": "qwen3.8:27b (local)", "contextWindow": 131072, "maxTokens": 49152,
                   "match": "Qwen3.8-27B"},
}

MODELS_JSON = Path.home() / ".pi" / "agent" / "models.json"


def detect_running_profile() -> str:
    """Best-effort: match the loaded GGUF filename against known profiles. Falls back to
    'coder' (this repo's default) if the server isn't reachable or the model is unrecognized."""
    try:
        with urllib.request.urlopen("http://127.0.0.1:8080/props", timeout=3) as r:
            props = json.load(r)
        model_path = props.get("model_alias") or props.get("model_path") or ""
        for key, profile in PROFILES.items():
            if profile["match"] in model_path:
                return key
    except Exception:
        pass
    return "coder"


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in (*PROFILES, "auto"):
        print(f"Usage: {sys.argv[0]} <{'|'.join((*PROFILES, 'auto'))}>", file=sys.stderr)
        sys.exit(1)
    profile_key = detect_running_profile() if sys.argv[1] == "auto" else sys.argv[1]
    profile = PROFILES[profile_key]

    data = json.loads(MODELS_JSON.read_text())
    model = data["providers"]["llama-local"]["models"][0]
    model["name"] = profile["name"]
    model["contextWindow"] = profile["contextWindow"]
    model["maxTokens"] = profile["maxTokens"]
    MODELS_JSON.write_text(json.dumps(data, indent=2) + "\n")
    print(f"[models.json] synced to '{profile_key}' profile "
          f"(contextWindow={profile['contextWindow']}, maxTokens={profile['maxTokens']})")


if __name__ == "__main__":
    main()
