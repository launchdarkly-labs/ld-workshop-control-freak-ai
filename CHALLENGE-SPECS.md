# Challenge Specifications

---

## Challenge 1 — Config, Variations & Per-Segment Model Routing

**Slug:** `01-model-routing`  
**Title:** "Route to the Right Model"  
**Estimated time:** 12 minutes

### Learning Objectives
- Create an AI Config with two variations
- Define a premium segment and attach a targeting rule
- Verify that model routing works live in the chat app

### Narrative
The team wants to give premium subscribers better AI responses using Claude Sonnet while keeping costs low for free-tier users with Haiku. Instead of branching in code, they'll use a LaunchDarkly AI Config.

### Learner Steps

1. In the LaunchDarkly UI, navigate to **AI Configs** and open the pre-created config `chat-assistant`.
2. Confirm **Variation A — Default**: model = `claude-haiku-4-5-20251001`, system prompt = starter prompt.
3. Create **Variation B — Premium**: model = `claude-sonnet-4-6`, same base prompt.
4. Add a targeting rule: *If user is in segment `premium-users` → serve Variation B*.
5. Set default rule to Variation A.
6. Save & turn the config **On**.
7. In the chat app, send a message as a premium user — verify the model badge shows `sonnet`.
8. Send the same message as a free user — verify the model badge shows `haiku`.

### Callout: mode-permanent

> **⚠️ mode-permanent**  
> When you set an AI Config variation to `mode: permanent`, it locks that variation for the context so it cannot be overridden by subsequent targeting rule changes during the same session. This is useful for compliance scenarios where you need a guaranteed model for a given user, but be aware it bypasses future live updates until the session context resets.

### Check / Validation
- Automated check: `curl http://localhost:3000/api/model-info?plan=premium` returns `{"model":"claude-sonnet-4-6"}`.
- Automated check: `curl http://localhost:3000/api/model-info?plan=free` returns `{"model":"claude-haiku-4-5-20251001"}`.

### Setup Script Notes (`setup-workstation`)
- Clone/copy base repo app, install deps, start dev server on port 3000 (background).
- Run `bootstrap-ld.sh` to create the AI Config shell, segment, and SDK key env vars.
- The AI Config should be created **Off** with both variations present but no targeting rule — learner adds the rule.

---

## Challenge 2 — Live Prompt Edit (No Redeploy)

**Slug:** `02-live-prompt-edit`  
**Title:** "Change the Prompt, Not the Code"  
**Estimated time:** 8 minutes

### Learning Objectives
- Edit a system prompt in the LaunchDarkly AI Config UI
- Observe the behavior change immediately in the running app without any redeploy
- Appreciate the separation of prompt management from code deployment

### Narrative
The product team wants to tweak how the assistant responds — maybe make it more concise, give it a persona, or constrain its topic focus. With LaunchDarkly AI Configs, this is a UI change, not a PR.

### Learner Steps

1. Open the chat app and send a test message. Note the response style.
2. In the LaunchDarkly UI, open `chat-assistant` → **Variation A (Default)**.
3. Edit the system prompt. The assignment gives a few inspiration examples but emphasizes: **be creative, make it yours**.
   - Example ideas: "Respond only in haiku.", "You are a pirate who happens to know everything about software.", "Answer in bullet points, max 3 bullets."
4. Save the variation.
5. Return to the chat app — **do not reload**, just send the same message again.
6. Observe the changed behavior in real time.

### Encouragement Note in Assignment
> ✨ **This is your playground.** There's no wrong answer here. The goal is to feel the magic of changing AI behavior without touching code or restarting anything. Get weird with it.

### Check / Validation
Soft check — assignment asks the learner to click "Check" after they've confirmed they saw a behavior change. No automated API check needed here; human verification is the point.

### Setup Script Notes (`setup-workstation`)
- App is already running from Challenge 1 (persistent container).
- No additional setup needed beyond ensuring the config is in the state left by Challenge 1.
- Optionally reset system prompt to a known baseline so the diff is obvious.

---

## Challenge 3 — Eval Setup: Attach a Judge & Run

**Slug:** `03-eval-setup`  
**Title:** "Measure Before You Ship"  
**Estimated time:** 12 minutes

### Learning Objectives
- Understand LaunchDarkly Evals as a quality gate
- Upload a pre-built dataset and attach an LLM judge
- Run an eval and interpret the results

### Narrative
Before rolling Sonnet out to all premium users, the team wants confidence the variation actually produces better output. They'll run a quick eval using the pre-loaded dataset and an LLM-as-judge.

### Learner Steps

1. In the LaunchDarkly UI, navigate to **AI Configs → chat-assistant → Evals**.
2. Click **Create eval run**.
3. Select **Dataset** → the eval dataset has been pre-uploaded as `workshop-eval-dataset` (done by setup script).
4. Select **Judge**: `claude-haiku-4-5` (cost-efficient judge for demo).
5. Select **Variations to evaluate**: Variation A and Variation B.
6. Click **Run eval**.
7. When the run completes, compare the quality scores for each variation.
8. Observe that Variation B (Sonnet) scores higher on complex prompts.

### Dataset Notes
- Dataset file: `data/eval-dataset.csv` (40 rows)
- Uploaded to LD via API in `setup-workstation` using `LD_API_KEY`
- Dataset name in LD UI: `workshop-eval-dataset`
- Schema: `input`, `expected_output`, `variables`, `metadata`

### Check / Validation
- Automated: `curl` the LD REST API to check that an eval run exists for `chat-assistant` with status `completed`.

### Setup Script Notes (`setup-workstation`)
- Upload `data/eval-dataset.csv` to LaunchDarkly via the Evals API.
- API endpoint (REST): `POST /api/v2/ai-configs/{aiConfigKey}/eval-datasets`
- Store the dataset ID in a file for later use in Challenge 4.

---

## Challenge 4 — Auto-Rollback via Judge Trigger

**Slug:** `04-auto-rollback`  
**Title:** "Guardrails That Fire Themselves"  
**Estimated time:** 10 minutes

### Learning Objectives
- Configure a judge-based monitoring rule on an AI Config
- Understand how LaunchDarkly can automatically roll back an AI variation
- Watch auto-rollback happen live via a pre-loaded bad scenario

### Narrative
Quality regressions happen. The team wants LaunchDarkly to detect when a new variation's judge scores drop below a threshold and automatically roll back — no 2am pager needed.

### Learner Steps

1. In the LaunchDarkly UI, navigate to **AI Configs → chat-assistant → Monitoring**.
2. Click **Add judge rule**.
3. Configure:
   - Judge: `claude-haiku-4-5`
   - Metric: **Quality score**
   - Threshold: `< 0.6`
   - Action: **Roll back to previous variation**
4. Save the rule and enable monitoring.
5. In the terminal, run the pre-loaded rollback scenario script:
   ```bash
   ./scripts/trigger-bad-scenario.sh
   ```
   This script sends a batch of low-quality-triggering prompts through the app, simulating a regression.
6. Watch the LaunchDarkly UI — within ~30 seconds, the config rolls back automatically.
7. Verify in the chat app that the model has reverted to the safe default.

### Pre-loaded Scenario
`trigger-bad-scenario.sh` sends ~10 requests that the judge will score poorly (e.g., deliberately vague, contradictory, or nonsensical inputs paired with the variation under test). The script is pre-written in the repo; learners just run it.

### Check / Validation
- Automated: Check that the AI Config's current serving variation has reverted to Variation A (default).

### Setup Script Notes (`setup-workstation`)
- Pre-write `scripts/trigger-bad-scenario.sh` (included in repo).
- Attach the monitoring judge rule via the LD API so learners only need to review/confirm, not create from scratch. (Optional — UX decision: do they configure or just observe?)
- Confirm the app is still running on port 3000.

---

## Shared Notes Across All Challenges

### Tabs Layout
```
[ Terminal ]  [ Chat App (port 3000) ]  [ LaunchDarkly (browser) ]
```

### Persistent State
Challenges share the same container. The app runs continuously. LD state (config, segments, eval runs) persists between challenges naturally.

### Cleanup Hooks
Each `cleanup` script should:
- Leave the app running
- Not destroy LD resources (they are needed by subsequent challenges)
- Only perform any resets explicitly noted in the spec above
