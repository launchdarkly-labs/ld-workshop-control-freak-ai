---
slug: welcome
id: u9h6ac326vm8
type: challenge
title: Welcome to ToggleWear
teaser: Meet ToggleWear, meet Otto-to-be, and get oriented before you start building.
notes:
- type: text
  contents: ToggleWear sells LaunchDarkly-branded apparel. They want an AI shopping
    assistant on the site. Over the next few challenges you'll build, personalize,
    evaluate, and guard that assistant. His name is going to be Otto.
tabs:
- id: x4bfh4g2uh11
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: 449i812xi2h2
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: 3fzxr3qqqgtj
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 300
enhanced_loading: null
---

# Welcome

Over the next ~90 minutes, you're going to build an AI shopping assistant for **ToggleWear**, a fictional online retailer of LaunchDarkly-branded apparel. The assistant's name is **Otto**. Right now Otto doesn't exist — by the end of this track, he'll be live in the [ToggleWear](#tab-1) storefront, targeted by user tier, evaluated against a golden dataset, and shipping behind a guarded rollout that auto-reverts when quality drops.

You're going to do this using **LaunchDarkly AgentControl**: prompts, models, and rollout strategy as runtime configuration instead of hardcoded values.

# What you'll do

| # | Beat |
|---|---|
| 01 | Create Otto's first Config, wire him into the app, and target a premium-tier Otto by user attribute. |
| 02 | Change Otto's personality without redeploying. |
| 03 | Run an offline evaluation against a golden dataset and grade Otto with an LLM judge. |
| 04 | Roll out a risky new model behind a guarded rollout and watch it auto-revert. |

# Assumptions

This track assumes you already know the LaunchDarkly basics — flags, contexts, environments, targeting rules. If you don't, the [LaunchDarkly Basics](https://launchdarkly.com) track is a better starting point.

The tabs on the right will all be useful: [LaunchDarkly](#tab-0) for the LD UI, [ToggleWear](#tab-1) for the live storefront, [Code Editor](#tab-2) for `server.py` and other repo files.

Click **Check** below when you're ready to start.
