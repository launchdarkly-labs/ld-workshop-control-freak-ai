#!/bin/bash
#
# bootstrap-ld.sh — provision the LaunchDarkly resources that the Control Freak
# track depends on. Runs once during track_scripts/setup-workstation.
#
# Creates:
#   - the `premium-users` segment (rule: tier == "premium")
#   - the `otto-assistant` AgentControl Config (Off, no targeting rule)
#   - Variation A "Default — Haiku" (claude-haiku-4-5-20251001, starter prompt)
#   - Variation B "Premium — Sonnet" (claude-sonnet-4-6, same starter prompt)
#
# Inputs (env vars):
#   LAUNCHDARKLY_ACCESS_TOKEN    REST API token, Editor role on the project
#   LAUNCHDARKLY_AG_API_TOKEN    AgentControl token (may equal the above)
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
AI_CONFIG_KEY="otto-assistant"
SEGMENT_KEY="premium-users"

: "${LAUNCHDARKLY_ACCESS_TOKEN:?LAUNCHDARKLY_ACCESS_TOKEN must be set}"
: "${LD_PROJECT_KEY:?LD_PROJECT_KEY must be set}"

AG_TOKEN="${LAUNCHDARKLY_AG_API_TOKEN:-$LAUNCHDARKLY_ACCESS_TOKEN}"

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
# 2. Create the `premium-users` segment (rule: tier == "premium")
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

# Add the rule: tier == "premium"
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
# 3. Create the AgentControl Config `otto-assistant`
# ---------------------------------------------------------------------------
# NOTE: The AgentControl REST surface is evolving. If POST fails with a 404,
# verify the path against https://launchdarkly.com/docs/home/ai-configs and
# adjust both this script and the docs link in the assignment.
log "Creating AgentControl Config $AI_CONFIG_KEY"
config_payload=$(jq -n \
  --arg key "$AI_CONFIG_KEY" \
  '{
    key: $key,
    name: "Otto Assistant",
    mode: "completion",
    description: "ToggleWear shopping assistant. Used by the Control Freak track."
  }')

curl -fsS -X POST \
  "${LD_API}/projects/${LD_PROJECT_KEY}/ai-configs" \
  -H "Authorization: ${AG_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$config_payload" \
  > /dev/null \
  || log "Config $AI_CONFIG_KEY may already exist — continuing."

# ---------------------------------------------------------------------------
# 4. Create both variations. Config remains Off; learner adds targeting in Ch1.
# ---------------------------------------------------------------------------
STARTER_PROMPT=$(cat <<'PROMPT'
You are Otto, the shopping assistant for ToggleWear — an online retailer of
LaunchDarkly-branded apparel. Answer questions about products, sizing, shipping,
and store policy. Be accurate. Be concise. Stay on topic.
PROMPT
)

create_variation() {
  local var_key="$1"
  local var_name="$2"
  local model_name="$3"

  log "Creating variation $var_key (model=$model_name)"
  local payload
  payload=$(jq -n \
    --arg key "$var_key" \
    --arg name "$var_name" \
    --arg model "$model_name" \
    --arg prompt "$STARTER_PROMPT" \
    '{
      key: $key,
      name: $name,
      model: { name: $model },
      messages: [
        { role: "system", content: $prompt }
      ]
    }')

  curl -fsS -X POST \
    "${LD_API}/projects/${LD_PROJECT_KEY}/ai-configs/${AI_CONFIG_KEY}/variations" \
    -H "Authorization: ${AG_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    > /dev/null \
    || log "Variation $var_key may already exist — continuing."
}

create_variation "default-haiku" "Default — Haiku"  "claude-haiku-4-5-20251001"
create_variation "premium-sonnet" "Premium — Sonnet" "claude-sonnet-4-6"

# ---------------------------------------------------------------------------
# 5. Emit env vars for downstream consumers
# ---------------------------------------------------------------------------
cat > /tmp/control-freak-env <<EOF
export LD_SDK_KEY="${LD_SDK_KEY}"
export LD_PROJECT_KEY="${LD_PROJECT_KEY}"
export LD_ENVIRONMENT_KEY="${LD_ENVIRONMENT_KEY}"
EOF

log "Done. Wrote /tmp/control-freak-env (LD_SDK_KEY, LD_PROJECT_KEY, LD_ENVIRONMENT_KEY)."
