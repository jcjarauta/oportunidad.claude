#!/bin/bash
set -euo pipefail

# Restores ~/.clasprc.json from the CLASP_CREDENTIALS secret at session start.
#
# clasp (>=2.5.0) expects the global credentials file in this shape:
#   { "token": {...}, "oauth2ClientSettings": {...}, "isLocalCreds": false }
# but CLASP_CREDENTIALS is stored in the older nested shape clasp login used
# to produce: { "tokens": { "default": {...} } }. Writing it verbatim makes
# `clasp pull`/`clasp push` fail with "Cannot read properties of undefined
# (reading 'access_token')" even though `clasp status` still works (it
# doesn't need a token). This script converts between the two shapes.

if [ -z "${CLASP_CREDENTIALS:-}" ] || [ -f "$HOME/.clasprc.json" ]; then
  exit 0
fi

umask 077

python3 - <<'PYEOF'
import json
import os

raw = os.environ["CLASP_CREDENTIALS"]
data = json.loads(raw)

# Accept whichever shape the secret happens to be stored in.
t = (data.get("tokens") or {}).get("default") or data.get("token") or data

default_scope = " ".join([
    "https://www.googleapis.com/auth/script.deployments",
    "https://www.googleapis.com/auth/script.projects",
    "https://www.googleapis.com/auth/script.webapp.deploy",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
    "https://www.googleapis.com/auth/drive.file",
    "https://www.googleapis.com/auth/service.management",
    "https://www.googleapis.com/auth/logging.read",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
])

out = {
    "token": {
        "access_token": t.get("access_token"),
        "refresh_token": t.get("refresh_token"),
        "scope": t.get("scope") or default_scope,
        "token_type": t.get("token_type") or "Bearer",
        "expiry_date": t.get("expiry_date"),
    },
    "oauth2ClientSettings": {
        "clientId": t.get("client_id"),
        "clientSecret": t.get("client_secret"),
        "redirectUri": "http://localhost",
    },
    "isLocalCreds": False,
}

path = os.path.expanduser("~/.clasprc.json")
with open(path, "w") as f:
    json.dump(out, f)
PYEOF

chmod 600 "$HOME/.clasprc.json"
