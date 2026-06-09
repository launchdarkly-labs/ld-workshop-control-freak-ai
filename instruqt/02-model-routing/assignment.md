---
slug: model-routing
type: challenge
title: Route to the Right Model
teaser: Send premium shoppers to Claude Sonnet, keep everyone else on Haiku — all
  from AgentControl, no redeploy.
notes:
- type: text
  contents: ToggleWear wants premium subscribers to get better answers from Otto using
    Claude Sonnet, while keeping costs low for free-tier shoppers with Haiku. Instead
    of branching in code, you'll do it with an AgentControl Config and a targeting
    rule.
tabs:
- id: goygwiedmm6t
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: qtkaszi2g6eg
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3333
- id: 1tajqkvkvvst
  title: Terminal
  type: terminal
  hostname: workstation
difficulty: ""
timelimit: 1200
enhanced_loading: null
---

# Why route by tier?

A single model rarely fits every customer. Premium shoppers expect nuance and patience; free-tier shoppers are fine with quick, factual answers. With AgentControl, the *same code path* can serve different models to different audiences — the routing decision lives in the Config, not in `if` statements.

By the end of this challenge:

- Otto's `otto-assistant` Config has a second variation, **Premium — Sonnet**, sitting alongside the **Default — Haiku** one you created in Ch01.
- A targeting rule routes the `premium-users` segment to the Sonnet variation.
- The chat app's model badge changes when you toggle your tier between Free and Premium.

# Create the Premium variation

Open the [LaunchDarkly](#tab-0) tab. Navigate to **Agents → Configs → otto-assistant** and click **+ Add variation**.

1. **Name**:
```text
Premium — Sonnet
```
2. **Key**:
```text
premium-sonnet
```
3. **Model**: pick **Bedrock** → **anthropic.claude-sonnet-4-6**.
4. **System prompt**: use the *same* starter prompt as the Haiku variation. (You can copy-paste it from the Default — Haiku variation page.) Keeping the prompt identical isolates the experiment to the model swap — that matters for the eval in Ch04.
5. Click **Review and save**, then **Save changes**.

You now have two variations with identical prompts and different models. The next step is to *route* between them.

# Add the targeting rule

1. Click the **Targeting** tab.
2. Confirm the environment selector reads **Test**.
3. Under **Targeting rules**, click **+ Add rule**.
4. Name the rule: `Premium users get Sonnet`.
5. Set the clause: **Context kind** `user` · **Attribute** is in **segment** · **Value** `premium-users`.
6. Serve: **Premium — Sonnet**.
7. Confirm the **Default rule** serves **Default — Haiku**.
8. Click **Review and save**, then **Save changes**.

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
