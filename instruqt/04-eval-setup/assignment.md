---
slug: eval-setup
type: challenge
title: Measure Before You Ship
teaser: Run an offline eval against a pre-loaded 40-row dataset with an LLM judge,
  then compare quality scores across both variations.
notes:
- type: text
  contents: Before promoting Sonnet to all premium users, the team wants confidence
    the variation actually produces better answers. AgentControl Evals give you that
    confidence in minutes.
tabs:
- id: rsp0jjjmerum
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: rr2do9ytkklb
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3333
- id: 5x7p4yehwcrh
  title: Terminal
  type: terminal
  hostname: workstation
difficulty: ""
timelimit: 900
enhanced_loading: null
---

# What an offline eval is

An **offline eval** runs every row of a dataset through one or more Config variations and asks an LLM judge to score the outputs. You don't need real traffic, and you don't need to ship. You get a quality signal *before* the rollout decision.

For this lab the dataset (`workshop-eval-dataset`, 40 rows across factual QA, summarization, sentiment, entity extraction, structured output, and a few premium-style asks) was already uploaded for you when this challenge started — check the terminal output.

# Create the eval run

Open the [LaunchDarkly](#tab-0) tab. Navigate to **Agents → Configs → otto-assistant → Evals**.

1. Click **Create eval run**.
2. **Dataset**: select `workshop-eval-dataset`.
3. **Judge model**: select `claude-haiku-4-5` (cost-efficient; good enough for a demo signal).
4. **Variations to evaluate**: check **Default — Haiku** and **Premium — Sonnet** both.
5. Click **Run eval**.

The run takes a couple of minutes. While it runs, glance at the dataset preview — it deliberately mixes easy factual asks (where both models should ace it) with harder rewrite/empathy prompts (where Sonnet should pull ahead).

# Read the results

When the run completes:

1. Open the results page.
2. Compare the **overall quality score** for each variation.
3. Drill into a few individual rows — especially the premium-flagged ones (sentiment, empathetic-rewrite, exec-summary). Note where Sonnet's output is meaningfully better and where Haiku is close enough.

You should see Sonnet score noticeably higher on the complex prompts, with the two variations roughly tied on simple factual lookups.

This is the data you'd bring to a rollout review.

# Check

When the eval run shows status **completed** in the LD UI, click **Check** below. The verification queries the LD REST API for an eval run on `otto-assistant` with status `completed`.
