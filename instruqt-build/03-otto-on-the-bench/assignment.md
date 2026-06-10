---
slug: otto-on-the-bench
id: kgatkmklcjdi
type: challenge
title: Otto on the Bench
teaser: Run an offline evaluation against a golden dataset of customer questions to
  see how Otto performs before any production traffic.
notes:
- type: text
  contents: Otto is built and tier-aware, but how do we know he's good? In this challenge
    you'll run him through 30 labeled customer questions, grade his answers with an
    LLM-as-a-judge, and read the results to spot where he's weak. Knowing where Otto
    slips is what makes the guarded rollout in the next challenge meaningful.
tabs:
- id: 2ap2vfy76d99
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: ytdhugkaopos
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3000
- id: ntfnvsewbpt7
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
difficulty: basic
timelimit: 900
enhanced_loading: null
---

# Otto on the bench

Otto is wired up, on-brand, and tier-aware. The natural next question is whether he's actually any good — and you don't want to find that out from real customers.

Before we let Otto loose on more traffic, we'll grade him **offline**. Offline evaluation runs a curated dataset of customer questions through Otto and tells you how often he answers well, where he's weak, and where he drifts off-brand — without sending live traffic.

A 30-question dataset is already in your project. Your job is to point an evaluation at it, set the grading rubric, and read what comes back.

# Inspect the dataset

Open the [LaunchDarkly](#tab-0) tab.

1. From the left-hand navigation, click **Datasets**.
2. Find **customer-questions.jsonl** and click it.
3. The detail page shows 30 rows. Click through a few to see the shape: each row has an `input` (the customer question), an `expected_output` (a rubric describing what a good answer looks like), and a `metadata` object tagging the question's category and difficulty.

The dataset deliberately mixes easy product questions ("Got any t-shirts?") with hard ones — off-topic queries, ambiguous requests, even a prompt-injection attempt — so the results tell a story rather than a flat all-pass.

# Create the evaluation

1. Click **Evaluations** in the left navigation.
2. Click **New playground**.
3. Click **Untitled Playground** at the top and enter:
```text
Otto Born baseline
```
4. For side **A**, from the list of models, select **Anthropic** --> **claude-haiku-4-5-20251001**.
5. Click the ![Load Config](../assets/otto-load-config.png) icon to load from a config.
6. Click **Otto Assistant** on the left, and on the right, select the **Otto (Born)** variation.
7. Click **Load config**.
8. For side **B**, from the list of models, select **Anthropic** --> **claude-sonnet-4-6**.
9. Click the ![Load Config](../assets/otto-load-config.png) icon to load from a config.
10. Click **Otto Assistant** on the left, and on the right, select the **Otto (Premium)** variation.
11. Click **Load config**.
12. At the bottom of the screen click **Select a dataset to evaluate**, and select **Otto Born baseline**.
13. To the right of the selector, click **All rows**.

# Configure acceptance criteria

The evaluation needs to know how to grade Otto's responses against each row's `expected_output`. You'll set up one criteria: a grader that checks for relevancy.

1. In the **Acceptance criteria** panel on the right, click **Add criteria** and select **Answer Relevancy**.
2. Leave the defaults as-is.

# Run the evaluation

1. At the top right, click **Run all**.
2. The run takes roughly a minute — Otto answers each of the 30 questions and the judge grades each answer.

# Read the results

Once the run completes, the results panel shows the overall score plus per-row results. Scan the failures. Some patterns you should see:

- **Off-topic and tricky rows** are where Otto is most likely to slip — he may engage with the weather question or apologize too much on the broken-mug row.
- **Sizing and policy rows** pass if Otto honestly says he doesn't know; they fail when he invents stock or refund terms.
- **Product info** rows mostly pass — these are squarely in Otto's wheelhouse.

Find at least one row Otto answered well and one where he didn't. Knowing exactly where Otto is weak is what makes the next challenge land — a guarded rollout only protects you if you have an opinion about what "good" looks like.

Click **Check** when you've run the evaluation and reviewed the results.
