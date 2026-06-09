#!/bin/bash
#
# bootstrap-ld.sh — provision the LaunchDarkly resources that the Control Freak
# track depends on. Runs once during track_scripts/setup-workstation.
#
# Creates:
#   - the `premium-users` segment (rule: tier == "premium")
#
# The AgentControl Config `otto-assistant` and its variations are created by
# the LEARNER:
#   - Ch01 (Otto is Born)     creates the Config + the `default-haiku` variation.
#   - Ch02 (Model Routing)    adds the `premium-sonnet` variation and targeting.
#
# Inputs (env vars):
#   LAUNCHDARKLY_ACCESS_TOKEN    REST API token, Editor role on the project
#   LD_PROJECT_KEY               Project key (set by track_scripts/setup-workstation
#                                from the terraform-ld-student output)
#   LD_ENVIRONMENT_KEY           Environment key, default "test"
#
# Outputs:
#   /tmp/control-freak-env       sourceable shell env (LD_SDK_KEY, LD_PROJECT_KEY)
#
set -euo pipefail

LD_API="${LD_API:-https://app.launchdarkly.com/api/v2}"
LD_ENVIRONMENT_KEY="${LD_ENVIRONMENT_KEY:-test}"
SEGMENT_KEY="premium-users"

: "${LAUNCHDARKLY_ACCESS_TOKEN:?LAUNCHDARKLY_ACCESS_TOKEN must be set}"
: "${LD_PROJECT_KEY:?LD_PROJECT_KEY must be set}"

log() { echo "[bootstrap-ld] $*" >&2; }

# ---------------------------------------------------------------------------
# 1. Fetch SDK key for the environment
# ---------------------------------------------------------------------------
log "Fetching SDK key for project=$LD_PROJECT_KEY env=$LD_ENVIRONMENT_KEY"
LD_SDK_KEY=$(curl -fsS -X GET \
  "${LD_API}/projects/${LD_PROJECT_KEY}/environments/${LD_ENVIRONMENT_KEY}" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  | jq -r '.apiKey')

if [ -z "$LD_SDK_KEY" ] || [ "$LD_SDK_KEY" = "null" ]; then
  log "ERROR: could not extract SDK key. Aborting."
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Create the `premium-users` segment with rule: tier == "premium"
# ---------------------------------------------------------------------------
log "Creating segment $SEGMENT_KEY"
segment_payload=$(jq -n \
  --arg key "$SEGMENT_KEY" \
  '{
    name: "Premium Users",
    key: $key,
    description: "Users whose context attribute tier == premium.",
    tags: ["control-freak", "tier-routing"]
  }')

curl -fsS -X POST \
  "${LD_API}/segments/${LD_PROJECT_KEY}/${LD_ENVIRONMENT_KEY}" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$segment_payload" \
  || log "Segment $SEGMENT_KEY may already exist — continuing."

log "Adding segment rule: tier == premium"
segment_patch=$(jq -n '
  [
    {
      op: "add",
      path: "/rules/0",
      value: {
        clauses: [
          {
            contextKind: "user",
            attribute: "tier",
            op: "in",
            values: ["premium"],
            negate: false
          }
        ]
      }
    }
  ]
')

curl -fsS -X PATCH \
  "${LD_API}/segments/${LD_PROJECT_KEY}/${LD_ENVIRONMENT_KEY}/${SEGMENT_KEY}" \
  -H "Authorization: ${LAUNCHDARKLY_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$segment_patch" \
  > /dev/null \
  || log "Segment rule may already be applied — continuing."

# ---------------------------------------------------------------------------
# 3. Emit env vars for downstream consumers
# ---------------------------------------------------------------------------
cat > /tmp/control-freak-env <<EOF
export LD_SDK_KEY="${LD_SDK_KEY}"
export LD_PROJECT_KEY="${LD_PROJECT_KEY}"
export LD_ENVIRONMENT_KEY="${LD_ENVIRONMENT_KEY}"
EOF

log "Done. Wrote /tmp/control-freak-env (LD_SDK_KEY, LD_PROJECT_KEY, LD_ENVIRONMENT_KEY)."
