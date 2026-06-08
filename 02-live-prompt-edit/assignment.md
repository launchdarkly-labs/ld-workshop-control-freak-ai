---
slug: live-prompt-edit
type: challenge
title: Change the Prompt, Not the Code
teaser: Edit Otto's system prompt in the UI and watch the running app behave
  differently on the very next message — no deploy, no restart.
notes:
- type: text
  contents: The product team wants to tweak how Otto sounds. With AgentControl,
    that's a UI change, not a pull request.
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
timelimit: 600
---

# Feel the difference first

Open the [ToggleWear](#tab-1) tab. Switch the header dropdown to **Free user** (so we hit the Default — Haiku variation we'll be editing) and ask Otto:

```text
Got any t-shirts?
```

Note the style: brief, factual, a little dry. That's the starter prompt talking.

# Edit the prompt

Open the [LaunchDarkly](#tab-0) tab. Navigate to **Agents → Configs → otto-assistant**, then click into the **Default — Haiku** variation.

Find the **System** prompt and rewrite it. Some inspiration:

- *"Respond only in haiku."*
- *"You are a pirate who happens to know everything about software."*
- *"Answer in bullet points, max three bullets. No more."*
- *"You are Otto. You are extremely enthusiastic about every product. Use exclamation points."*

> ✨ **This is your playground.**
>
> There's no wrong answer here. The goal is to *feel* the magic of changing AI behavior without touching code, restarting anything, or shipping a PR. Get weird with it.

Click **Review and save**, then **Save changes**.

# Watch it change — live

Switch back to the [ToggleWear](#tab-1) tab. **Do not reload the page.** Send the same message:

```text
Got any t-shirts?
```

Otto's tone is different. The app is the same process you started this lab with — but the next call to AgentControl picked up your edit and threaded it straight into Bedrock.

That's the entire point: **prompts are configuration, not code.**

# Check

When you've seen Otto's tone change in response to your edit, click **Check**. There's no API gate here — the verification is in your own eyes.
