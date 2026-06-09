---
slug: auto-rollback
type: challenge
title: Guardrails That Fire Themselves
teaser: Wire a judge-based monitoring rule to the Config, trigger a deliberately bad
  scenario, and watch AgentControl roll back the variation automatically.
notes:
- type: text
  contents: Quality regressions happen. The team wants LaunchDarkly to detect when
    a variation's judge scores drop below a threshold and roll back on its own — no
    2 a.m. pager.
tabs:
- id: yg2vo35pypoa
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: 1pkelm8evl41
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3333
- id: vn6hrvmyuyyc
  title: Terminal
  type: terminal
  hostname: workstation
difficulty: ""
timelimit: 900
enhanced_loading: null
---

# Add a judge-based monitoring rule

Open the [LaunchDarkly](#tab-0) tab. Navigate to **Agents → Configs → otto-assistant → Monitoring**.

1. Click **Add judge rule**.
2. Configure:
   - **Judge**: `claude-haiku-4-5`
   - **Metric**: Quality score
   - **Threshold**: `< 0.6`
   - **Sample window**: last 10 evaluations (or the smallest available)
   - **Action**: Roll back to previous variation
3. Save the rule and flip monitoring **On**.

This tells AgentControl: *"keep grading the live traffic with the haiku judge. If the rolling quality score drops below 0.6 inside the sample window, revert the Config to the variation it was serving before this one."*

# Trigger the regression

Open the [Terminal](#tab-2) tab and run:

```bash
/opt/control-freak-ai/scripts/trigger-bad-scenario.sh
```

The script sends ten deliberately incoherent, contradictory, and unanswerable prompts through the chat app as a premium user (so the Sonnet variation gets exercised). Each one will receive a poor judge score. Watch the terminal — it prints one prompt per line.

# Watch the rollback

Switch to the [LaunchDarkly](#tab-0) tab on the **otto-assistant** Monitoring view.

Within ~30 seconds of the script finishing, the rule should fire:

- The current serving variation flips from **Premium — Sonnet** back to **Default — Haiku**.
- The Monitoring view shows an event entry: *judge threshold breached → rolled back*.
- Premium users in the chat app are now served Haiku, transparently.

# Confirm in the app

Switch to the [ToggleWear](#tab-1) tab. Set the dropdown to **Premium user** and send a fresh message. The meta line should now read `… · model: claude-haiku-4-5-20251001` — the rollback took effect end-to-end.

Quality regression detected, quality regression reverted. No human required.

# Check

When the Config has reverted to **Default — Haiku** for all users, click **Check**. The verification queries the Config's current serving variation via the LD REST API.
