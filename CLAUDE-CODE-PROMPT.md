# Claude Code Session Prompt

Paste this at the start of your Claude Code session (or use as the initial message).

---

## Context

You are building a new Instruqt track for LaunchDarkly based on the existing repo at:
`https://github.com/launchdarkly-labs/ld-workshop-ai-configs-intro`

The new track lives in a new repo:
`launchdarkly-labs/ld-workshop-ai-configs-evals-demo` (create/use this repo)

All planning documents are in the `/planning` folder of this repo:
- `PLANNING.md` — overview, constraints, open questions
- `CHALLENGE-SPECS.md` — per-challenge learner steps, callouts, and validation logic
- `FILE-STRUCTURE.md` — exact file list, scaffold notes, and app layer changes needed
- `DATA.md` — eval dataset schema, all 40 rows, and upload command

## Your Task

Build the complete track by:

1. **Read all four planning docs first** before writing any files.
2. **Fork/copy the base repo** into the new repo structure. Keep the existing app code intact.
3. **Create all files listed in FILE-STRUCTURE.md**, following the specs in CHALLENGE-SPECS.md.
4. **Copy `data/eval-dataset.csv`** — the full CSV content is in DATA.md. Write it verbatim.
5. **Make the minimal app layer changes** described in FILE-STRUCTURE.md (model badge, `/api/model-info` endpoint, plan context injection, `/api/chat` endpoint).
6. **Write all bash lifecycle scripts** (`setup-workstation` files, `bootstrap-ld.sh`, `trigger-bad-scenario.sh`). Use `set -euo pipefail`. Add comments. Prefer `curl` + `jq` for LD API calls.
7. **Verify the track.yml** is valid Instruqt format with all 4 challenges listed in order.

## Key Constraints (do not violate these)

- Single track, 4 challenges — do not split into multiple tracks.
- Challenge 1 assignment MUST contain the `mode-permanent` callout block.
- Challenge 2 assignment MUST include the creativity encouragement callout.
- Challenge 3 `setup-workstation` MUST upload the eval dataset via the LD API.
- Challenge 4 `setup-workstation` MUST make `scripts/trigger-bad-scenario.sh` executable.
- Model routing: `claude-sonnet-4-6` for premium, `claude-haiku-4-5-20251001` as default.
- Do NOT hardcode API keys — always read from environment variables.

## Before Writing Scripts

For any LaunchDarkly API calls in the setup scripts, verify the current endpoint paths by
fetching: `https://launchdarkly.com/docs/home/ai-configs/evals` and
`https://launchdarkly.com/docs/api` to confirm eval dataset upload, AI Config creation,
and monitoring rule endpoints. These may have changed and should not be assumed from training data.

## Open Questions to Resolve Before Coding

Check `PLANNING.md` → "Questions / Assumptions" section and resolve any that block you.
If you cannot resolve an item (e.g., need a human decision), leave a `TODO:` comment in
the relevant file and continue.

## Definition of Done

- [ ] All files in FILE-STRUCTURE.md exist in the repo
- [ ] `track.yml` passes `instruqt validate`
- [ ] `npm run dev` starts successfully in the app directory
- [ ] `bootstrap-ld.sh` runs without error when `LD_API_KEY` is set
- [ ] `data/eval-dataset.csv` has 40 rows with correct schema
- [ ] All `setup-workstation` scripts are executable (`chmod +x`)
- [ ] No API keys hardcoded anywhere
- [ ] All `TODO:` comments documented for human review
