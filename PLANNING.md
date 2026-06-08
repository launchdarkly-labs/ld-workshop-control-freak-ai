# Instruqt Track Planning Brief
## Track: LaunchDarkly AI Configs — Model Routing, Live Editing, Evals & Auto-Rollback

---

## Overview

A single 4-challenge Instruqt track forked from  
`https://github.com/launchdarkly-labs/ld-workshop-ai-configs-intro`

The track tells a coherent story in ~45 minutes:

> "You configure an AI feature flag that routes to different models based on plan tier, tune the prompt live without redeploying, validate quality with an eval run, and watch LaunchDarkly auto-roll back when a rogue scenario degrades quality."

---

## Repo Bootstrap

```bash
# Starting point — fork or clone the base repo into a new repo:
# launchdarkly-labs/ld-workshop-ai-configs-evals-demo  (suggested name)

git clone https://github.com/launchdarkly-labs/ld-workshop-ai-configs-intro.git ld-workshop-ai-configs-evals-demo
cd ld-workshop-ai-configs-evals-demo
git remote remove origin
git remote add origin git@github.com:launchdarkly-labs/ld-workshop-ai-configs-evals-demo.git
```

---

## Track Structure (Instruqt)

```
track.yml
instruqt-track.yml   ← Instruqt manifest
challenges/
  01-model-routing/
    assignment.md
    setup-workstation          ← bash lifecycle hook
    cleanup
  02-live-prompt-edit/
    assignment.md
    setup-workstation
    cleanup
  03-eval-setup/
    assignment.md
    setup-workstation          ← uploads eval-dataset.csv here
    cleanup
  04-auto-rollback/
    assignment.md
    setup-workstation
    cleanup
scripts/
  bootstrap-ld.sh              ← creates LD project/flags/segments via API
  setup-app.sh                 ← installs deps, sets env vars
data/
  eval-dataset.csv             ← the 40-row eval dataset (see DATA.md)
```

---

## Challenge Summaries

See `CHALLENGE-SPECS.md` for full per-challenge detail.

| # | Title | Core Skill | Time |
|---|-------|-----------|------|
| 1 | Config, Variations & Per-Segment Model Routing | AI Config + targeting rules | ~12 min |
| 2 | Live Prompt Edit (No Redeploy) | Real-time prompt swap | ~8 min |
| 3 | Eval Setup — Attach a Judge & Run | LaunchDarkly Evals UI | ~12 min |
| 4 | Auto-Rollback via Judge Trigger | Guarded releases + judge | ~10 min |

---

## Environment / Sandbox Requirements

- Ubuntu 22 or 24 container
- Node 20 LTS (app runtime — mirrors base repo)
- `jq`, `curl` pre-installed
- Env vars injected via Instruqt secrets:
  - `LD_API_KEY` (personal access token, Editor role on the workshop project)
  - `LD_SDK_KEY` (server-side SDK key for the workshop environment)
  - `ANTHROPIC_API_KEY`
- Port 3000 exposed for the chat app tab

---

## Files to Produce (Claude Code Session Scope)

1. `track.yml` — updated track manifest (title, description, icon, tags)
2. `instruqt-track.yml` — Instruqt metadata
3. `challenges/01-model-routing/assignment.md`
4. `challenges/01-model-routing/setup-workstation`
5. `challenges/02-live-prompt-edit/assignment.md`
6. `challenges/02-live-prompt-edit/setup-workstation`
7. `challenges/03-eval-setup/assignment.md`
8. `challenges/03-eval-setup/setup-workstation` ← copies `data/eval-dataset.csv`
9. `challenges/04-auto-rollback/assignment.md`
10. `challenges/04-auto-rollback/setup-workstation`
11. `scripts/bootstrap-ld.sh`
12. `data/eval-dataset.csv` (40 rows — already generated, see `DATA.md`)
13. Any app-layer changes needed to the base repo's chat app

---

## Key Decisions / Constraints

- **Single track, 4 challenges** — no separate tracks.
- **Base app is the shopping-assistant chat app** from the base repo. Extend it; do not rewrite.
- **Model routing**: Sonnet (`claude-sonnet-4-6`) for `plan == premium`, Haiku (`claude-haiku-4-5`) as default.
- **mode-permanent callout** must appear in Challenge 1 assignment as a highlighted note (see spec).
- **Challenge 2** should explicitly encourage the learner to be creative with prompt changes — the assignment should not be prescriptive about *what* to change.
- **Eval dataset** is pre-loaded by `setup-workstation` in Challenge 3 (not hand-typed by learner).
- **Auto-rollback in Challenge 4** must be fully scripted — the learner watches it happen via a pre-loaded scenario, not by injecting bad traffic manually.

---

## Questions / Assumptions

Before the Claude Code session starts, resolve these:

1. **New repo name** — `ld-workshop-ai-configs-evals-demo` assumed. Confirm or override.
2. **LD project key** — assumed `ai-configs-workshop`. Confirm the bootstrap script target.
3. **Segment name for premium** — assumed `premium-users`. Confirm.
4. **Judge model** — Challenge 3 & 4 use an LLM-as-judge. Assumed `claude-haiku-4-5` for cost. Confirm.
5. **Auto-rollback threshold** — assumed quality score < 0.6 triggers rollback in Challenge 4. Confirm.
6. **Tab layout** — assumed: Terminal | Chat App | LaunchDarkly. Confirm.
