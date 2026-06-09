---
slug: otto-is-born
type: challenge
title: Otto is Born
teaser: Create Otto's first AgentControl Config, give him a starting prompt, and
  wire him into the ToggleWear app. By the end he'll say his first real words.
notes:
- type: text
  contents: Today is Otto's first day. The ToggleWear storefront has a chat widget
    that returns a canned "not wired up yet" line. You'll create his Config in
    AgentControl, give him a starting prompt and a Haiku model, then paste a few
    lines of SDK code into the server to bring him online. After this, every
    subsequent challenge is about *controlling* what you just built.
tabs:
- id: launchdarkly
  title: LaunchDarkly
  type: browser
  hostname: launchdarkly
- id: togglewear
  title: ToggleWear
  type: service
  hostname: workstation
  port: 3333
- id: editor
  title: Code Editor
  type: service
  hostname: workstation
  port: 8080
- id: terminal
  title: Terminal
  type: terminal
  hostname: workstation
difficulty: ""
timelimit: 1200
---

# Meet Otto — almost

Open the [ToggleWear](#tab-1) tab and click **Chat with Otto** in the bottom-right. Ask him anything. He'll tell you he isn't wired up yet. We're going to fix that.

By the end of this challenge:

- Otto exists as a **Config** in AgentControl.
- He has a starting prompt and a starting model (Claude Haiku 4.5 on Bedrock).
- The ToggleWear app evaluates the Config on each `/chat` call.
- Otto says his first real words.

# Create Otto's Config

Open the [LaunchDarkly](#tab-0) tab.

1. From the left-hand navigation, expand **Agents**.
2. Click **Configs**.
3. Click **Create config** in the upper right.
4. For **Name**, enter:
```text
Otto Assistant
```
5. For **Key**, confirm or set:
```text
otto-assistant
```
6. For **Mode**, select **Completion**.
7. Click **Create**.

# Add Otto's first variation

The Config exists but has no variations yet — nothing to serve. Add the **Default — Haiku** variation that every future challenge will key off.

1. On the Config detail page, you should already be on the new-variation form.
2. For **Name**, enter:
```text
Default — Haiku
```
3. For **Key**, set:
```text
default-haiku
```
4. Under **Model**, pick **Bedrock** → **anthropic.claude-haiku-4-5-20251001-v1:0**.
5. In the prompt area, choose **System** and paste:
```text
You are Otto, the shopping assistant for ToggleWear — an online retailer of LaunchDarkly-branded apparel. Answer questions about products, sizing, shipping, and store policy. Be accurate. Be concise. Stay on topic.
```
6. Click **Review and save**, then **Save changes**.

# Point the Test environment at Otto

By default the Config's `Test` environment is serving the "disabled" placeholder. Flip it.

1. Click the **Targeting** tab.
2. Confirm the environment selector reads **Test**.
3. Under **Default rule**, click **Edit** and select **Default — Haiku**.
4. Toggle the Config **On**.
5. Click **Review and save**, then **Save changes**.

# Wire Otto into the app

Open the [Code Editor](#tab-2) tab. Open `app/server.py`.

Find the block marked:

```python
# ─────────────────────────────────────────────────────────────────────
# Challenge 01 paste block — replace this stub with real Otto code.
```

Replace **everything between the opening marker and** `# ─── End Challenge 01 paste block ────` with:

```python
    # Build an LD context, evaluate the otto-assistant Config.
    context = _build_context(req.session_id, req.user_tier)
    cfg = ai_client.completion_config(OTTO_CONFIG_KEY, context, FALLBACK_CONFIG)

    if not cfg.enabled or cfg.model is None:
        return JSONResponse(status_code=503, content={
            "response": "Otto isn't enabled. Check the Config targeting.",
            "turn": turn, "turn_limit": TURN_LIMIT,
        })

    # Translate the Config's messages into Bedrock Converse format.
    system_blocks = []
    seed_messages = []
    for m in cfg.messages or []:
        if m.role == "system":
            system_blocks.append({"text": m.content})
        else:
            seed_messages.append({"role": m.role, "content": [{"text": m.content}]})

    # Merge in this session's prior turns + the new user message.
    with _state_lock:
        prior = list(_history[req.session_id])
    history_blocks = [{"role": m.role, "content": [{"text": m.content}]} for m in prior]
    bedrock_messages = seed_messages + history_blocks + [
        {"role": "user", "content": [{"text": req.message}]}
    ]

    model_id = resolve_bedrock_model(cfg.model.name)
    tracker = cfg.create_tracker()

    try:
        response = tracker.track_bedrock_converse_metrics(
            bedrock.converse(modelId=model_id, messages=bedrock_messages, system=system_blocks)
        )
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code")
        log.error("Bedrock ClientError: %s", code)
        return JSONResponse(status_code=502, content={
            "response": _bedrock_user_message(code),
            "turn": turn, "turn_limit": TURN_LIMIT,
        })

    assistant_text = _extract_text(response)
    with _state_lock:
        _history[req.session_id].append(LDMessage(role="user", content=req.message))
        _history[req.session_id].append(LDMessage(role="assistant", content=assistant_text))

    log.info(
        "chat session=%s tier=%s turn=%d model=%s",
        req.session_id, req.user_tier, turn, cfg.model.name,
    )

    return ChatResponse(
        response=assistant_text,
        turn=turn,
        turn_limit=TURN_LIMIT,
        model=cfg.model.name,
    )
```

> The block above replaces the entire stub `return ChatResponse(...)` plus the comment markers. Save the file — the togglewear service auto-reloads.

Read through the block to see how the AgentControl SDK pulls the model + system messages, then how Bedrock receives them. Every other challenge in this track changes *what those values are*, not the code path.

# Say hi to Otto

Switch to the [ToggleWear](#tab-1) tab. Click **Chat with Otto** and ask:

```text
Got any t-shirts?
```

Otto should answer for real. The meta line under the input will read `… · model: claude-haiku-4-5-20251001` — proof you're talking to the variation you just created.

# Check

When Otto responds with real content (not the "not wired up" stub), click **Check**. The verification confirms the Config exists with the `default-haiku` variation, the Test environment serves it, and `/chat` no longer returns the placeholder.
