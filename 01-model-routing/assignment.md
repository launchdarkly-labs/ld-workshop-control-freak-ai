---
slug: model-routing
type: challenge
title: Route to the Right Model
teaser: Send premium shoppers to Claude Sonnet, keep everyone else on Haiku — all
  from AgentControl, no redeploy.
notes:
- type: text
  contents: ToggleWear wants premium subscribers to get better answers from Otto
    using Claude Sonnet, while keeping costs low for free-tier shoppers with Haiku.
    Instead of branching in code, you'll do it with an AgentControl Config and a
    targeting rule.
tabs:
- id: launchdarkly
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: togglewear
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: terminal
  title: Terminal
  type: terminal
  hostname: workstation
difficulty: ""
timelimit: 1200
---

# Why route by tier?

A single model rarely fits every customer. Premium shoppers expect nuance and patience; free-tier shoppers are fine with quick, factual answers. With AgentControl, the *same code path* can serve different models to different audiences — the routing decision lives in the Config, not in `if` statements.

By the end of this challenge:

- Otto's `otto-assistant` Config has two variations: **Default — Haiku** and **Premium — Sonnet** (both already created for you).
- A targeting rule routes the `premium-users` segment to the Sonnet variation.
- The Config is **On**, and the chat app's model badge changes when you toggle your tier.

# Review the variations

Open the [LaunchDarkly](#tab-0) tab. Navigate to **Agents → Configs → otto-assistant**.

You should see two variations:

| Variation | Model | Use case |
|---|---|---|
| Default — Haiku | `claude-haiku-4-5-20251001` | Free-tier default |
| Premium — Sonnet | `claude-sonnet-4-6` | Premium subscribers |

Both share the same starter system prompt. We'll change that in Challenge 2.

# Add the targeting rule

1. Click the **Targeting** tab.
2. Confirm the environment selector reads **Test**.
3. Under **Targeting rules**, click **+ Add rule**.
4. Name the rule: `Premium users get Sonnet`.
5. Set the clause: **Context kind** `user` · **Attribute** is in **segment** · **Value** `premium-users`.
6. Serve: **Premium — Sonnet**.
7. Confirm the **Default rule** serves **Default — Haiku**.
8. Click **Review and save**, then **Save changes**.

# Turn the Config on

1. Still on the Targeting tab, flip the environment toggle to **On**.
2. Save.

> ⚠️ **mode-permanent** — about that toggle
>
> When you set an AgentControl variation to `mode: permanent`, it locks that variation for the context so subsequent targeting-rule changes can't override it during the same session. Useful for compliance scenarios where a given user *must* see a specific model, but be aware it bypasses future live updates until the session context resets. We are **not** using `mode: permanent` in this lab — but keep it in your back pocket.

# See routing in action

Open the [ToggleWear](#tab-1) tab and click **Chat with Otto**.

1. With the header dropdown set to **Free user**, ask: `Got any t-shirts?`
   - The meta line under the chat input should read `… · model: claude-haiku-4-5-20251001`.
2. Switch the dropdown to **Premium user** and ask the same question again.
   - The meta line should now read `… · model: claude-sonnet-4-6`.

Same code path. Different model. The routing decision lives in LaunchDarkly.

# Check

When you've seen the model badge flip, click **Check** below. The check probes `/api/model-info?plan=premium` and `/api/model-info?plan=free` and confirms they return the expected model IDs.
