# File Structure & Scaffold Specification

This document tells Claude Code exactly what files to create, what each should contain,
and what to leave for the human to fill in vs. what should be generated.

---

## Repo Root

### `track.yml`

Update from the base repo. Key fields to change:

```yaml
slug: ld-workshop-ai-configs-evals-demo
title: "LaunchDarkly AI Configs: Model Routing, Live Edits, Evals & Auto-Rollback"
description: >
  Build an AI Config that routes to Claude Sonnet for premium users and Haiku for free-tier.
  Then tune your prompt live without redeploying, run an eval with an LLM judge, and watch
  LaunchDarkly auto-roll back a bad variation automatically.
icon: https://storage.googleapis.com/instruqt-frontend/assets/launchdarkly/launchdarkly-icon.png
tags:
  - launchdarkly
  - ai-configs
  - evals
  - model-routing
  - feature-flags
level: beginner
estimated_time: 45
```

### `instruqt-track.yml`

Standard Instruqt manifest. Challenges should be listed in order with correct slugs.

---

## `challenges/01-model-routing/`

### `assignment.md`
Full markdown content per CHALLENGE-SPECS.md Challenge 1.
Must include:
- Numbered step list
- `mode-permanent` callout block (use `> ⚠️` blockquote or Instruqt `note` shortcode)
- Check instructions at the bottom

### `setup-workstation` (bash)
```bash
#!/bin/bash
set -euo pipefail

# 1. cd into app directory (base repo app)
# 2. npm install (if not already done)
# 3. Set env vars: LD_SDK_KEY, ANTHROPIC_API_KEY from Instruqt secrets
# 4. Start the dev server in background: nohup npm run dev > /tmp/app.log 2>&1 &
# 5. Run bootstrap-ld.sh to create LD resources
# 6. Wait for port 3000 to be ready: until curl -s http://localhost:3000 > /dev/null; do sleep 1; done
```

---

## `challenges/02-live-prompt-edit/`

### `assignment.md`
Per CHALLENGE-SPECS.md Challenge 2.
Must include the creativity encouragement callout.

### `setup-workstation` (bash)
```bash
#!/bin/bash
set -euo pipefail
# Minimal — app is already running.
# Optionally use LD API to reset system prompt to a known baseline string.
# Print a reminder to the terminal about what the current prompt is.
```

---

## `challenges/03-eval-setup/`

### `assignment.md`
Per CHALLENGE-SPECS.md Challenge 3.
Must reference that the dataset was pre-loaded (don't make them upload manually).

### `setup-workstation` (bash)
```bash
#!/bin/bash
set -euo pipefail

# 1. Copy /home/user/data/eval-dataset.csv into the app working directory
# 2. Upload the dataset to LD via REST API:
#    POST /api/v2/projects/{projectKey}/ai-configs/{aiConfigKey}/datasets
#    with the CSV file and name "workshop-eval-dataset"
# 3. Store the returned dataset ID to /tmp/ld-eval-dataset-id
# 4. Echo confirmation to terminal
```

> **Important:** The eval dataset CSV lives at `data/eval-dataset.csv` in the repo root.
> The setup script must copy or reference it from there. Do NOT hardcode the path to
> a temp directory — copy it to a predictable location and reference that.

---

## `challenges/04-auto-rollback/`

### `assignment.md`
Per CHALLENGE-SPECS.md Challenge 4.
Step 5 must show the exact command to run (`./scripts/trigger-bad-scenario.sh`).

### `setup-workstation` (bash)
```bash
#!/bin/bash
set -euo pipefail

# 1. (Optional) Use LD API to pre-attach judge monitoring rule — or leave for learner
# 2. Ensure trigger-bad-scenario.sh is executable: chmod +x scripts/trigger-bad-scenario.sh
# 3. Confirm app is still running on port 3000
```

---

## `scripts/bootstrap-ld.sh`

Creates all required LaunchDarkly resources for the track. Run once during Challenge 1 setup.

Resources to create:
- Project: `ai-configs-workshop` (or confirm existing)
- Environment: `workshop` (get SDK key, store to env)
- Segment: `premium-users` with a known test user key included
- AI Config: `chat-assistant` with:
  - Variation A (Default): model = `claude-haiku-4-5-20251001`, system prompt = starter text
  - Variation B (Premium): model = `claude-sonnet-4-6`, same starter system prompt
  - Config turned **Off** (learner turns it on)
  - No targeting rule yet (learner adds it)

```bash
#!/bin/bash
set -euo pipefail

LD_API_BASE="https://app.launchdarkly.com/api/v2"
PROJECT_KEY="ai-configs-workshop"

# Create segment
# Create AI Config shell
# Create both variations
# Output SDK key to /tmp/ld-sdk-key
```

---

## `scripts/trigger-bad-scenario.sh`

Pre-written script for Challenge 4. Sends ~10 requests through the chat app that will
score poorly with the LLM judge.

```bash
#!/bin/bash
# Sends low-quality prompts to trigger judge threshold breach
# These inputs are chosen to produce incoherent or non-matching outputs
# under Variation B, causing judge scores to drop below 0.6

PROMPTS=(
  "asdfjkl qwerty gibberish nonsense"
  "Tell me everything. No wait, nothing. Actually both."
  "Write a haiku about nothing using only verbs that are also nouns."
  # ... 7-8 more
)

for prompt in "${PROMPTS[@]}"; do
  curl -s -X POST http://localhost:3000/api/chat \
    -H "Content-Type: application/json" \
    -d "{\"message\": \"$prompt\", \"plan\": \"premium\"}" \
    > /dev/null
  sleep 2
done

echo "Scenario complete. Watch the LaunchDarkly UI for auto-rollback..."
```

---

## `data/eval-dataset.csv`

40-row CSV. Schema: `input`, `expected_output`, `variables`, `metadata`.

Already generated — see `DATA.md` for full content. Copy this file verbatim.

---

## App Layer Changes (base repo chat app)

The following additions are needed on top of the base repo app:

1. **Model badge** in chat UI — display which model variant responded (read from API response metadata).
2. **`/api/model-info` endpoint** — accepts `?plan=` query param, returns `{"model": "..."}`. Used by Challenge 1 automated check.
3. **Plan context injection** — the app must pass a `plan` attribute in the LaunchDarkly context so targeting rules can segment on it. Add a toggle or hardcode two test users (`premium-test-user`, `free-test-user`) accessible from the UI.
4. **`/api/chat` endpoint** — if not already present, ensure it accepts `{"message": "...", "plan": "..."}` for the trigger script in Challenge 4.

These are minimal additions. The base repo already handles the core AI Config SDK integration.

---

## What Claude Code Should NOT Change

- Core feature flag functionality in the base repo (keep it working)
- Any existing challenge content from the base repo (this is a new repo)
- The base repo's README (write a new one for this repo)
