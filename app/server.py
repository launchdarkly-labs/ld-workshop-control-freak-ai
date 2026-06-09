"""ToggleWear server — Control Freak track.

The /chat endpoint ships with a paste-block stub that Challenge 01 has the
learner replace with real AgentControl + Bedrock wiring. After Ch01 it's
fully alive; subsequent challenges teach the *control* layer on top of it
(model routing, live prompt edits, evals, auto-rollback).

Endpoints:
  POST /chat              — chat widget on the storefront (stub until Ch01)
  GET  /api/model-info    — synthetic Config evaluation; used by the Ch02 check
"""
import logging
import os
import threading
from collections import defaultdict, deque
from pathlib import Path
from typing import Optional

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from ldai import AICompletionConfigDefault, LDAIClient, LDMessage
from ldclient import Context, LDClient
from ldclient.config import Config as LDConfig
from pydantic import BaseModel

load_dotenv(override=True)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("togglewear")

STATIC_DIR = Path(__file__).parent / "static"
OTTO_CONFIG_KEY = "otto-assistant"
TURN_LIMIT = int(os.getenv("LD_CHAT_TURN_LIMIT", "30"))
HISTORY_LIMIT = 20
LD_SDK_KEY = os.environ["LD_SDK_KEY"]
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
AWS_PROFILE = os.getenv("AWS_PROFILE", "BedrockProfile")

ld_client = LDClient(LDConfig(LD_SDK_KEY))
ai_client = LDAIClient(ld_client)
boto_session = boto3.Session(profile_name=AWS_PROFILE, region_name=AWS_REGION)
bedrock = boto_session.client("bedrock-runtime")

FALLBACK_CONFIG = AICompletionConfigDefault(enabled=False)

# Bedrock needs the US cross-region inference profile ID (with the `us.`
# prefix) for the Anthropic models we use. Add new entries here as the
# workshop's model catalog grows.
BEDROCK_MODEL_IDS = {
    "claude-sonnet-4-6": "us.anthropic.claude-sonnet-4-6",
    "claude-sonnet-4-5": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
    "claude-haiku-4-5":  "us.anthropic.claude-haiku-4-5-20251001-v1:0",
    "claude-haiku-4-5-20251001": "us.anthropic.claude-haiku-4-5-20251001-v1:0",
    "anthropic.claude-sonnet-4-6":               "us.anthropic.claude-sonnet-4-6",
    "anthropic.claude-sonnet-4-5-20250929-v1:0": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
    "anthropic.claude-haiku-4-5-20251001-v1:0":  "us.anthropic.claude-haiku-4-5-20251001-v1:0",
}


def resolve_bedrock_model(ld_model_name: str) -> str:
    return BEDROCK_MODEL_IDS.get(ld_model_name, ld_model_name)


def _build_context(session_id: str, tier: str) -> Context:
    return Context.builder(session_id).set("tier", tier).build()


_turns: dict[str, int] = defaultdict(int)
_history: dict[str, deque] = defaultdict(lambda: deque(maxlen=HISTORY_LIMIT))
_state_lock = threading.Lock()

app = FastAPI(title="ToggleWear — Control Freak")
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


class ChatRequest(BaseModel):
    message: str
    user_tier: str = "free"
    session_id: str


class ChatResponse(BaseModel):
    response: str
    turn: int
    turn_limit: int
    model: Optional[str] = None


@app.get("/")
def index():
    return FileResponse(STATIC_DIR / "index.html")


@app.get("/healthz")
def healthz():
    return {"ok": True, "otto_config": OTTO_CONFIG_KEY, "region": AWS_REGION}


@app.get("/api/model-info")
def model_info(plan: str = "free"):
    """Probe which model the otto-assistant Config currently serves for a tier.

    Used by Challenge 1's automated check. Pure config eval — no Bedrock call.
    """
    context = _build_context(session_id=f"probe-{plan}", tier=plan)
    cfg = ai_client.completion_config(OTTO_CONFIG_KEY, context, FALLBACK_CONFIG)
    if not cfg.enabled or cfg.model is None:
        return JSONResponse(status_code=503, content={"error": "config not enabled"})
    return {"plan": plan, "model": cfg.model.name}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    with _state_lock:
        _turns[req.session_id] += 1
        turn = _turns[req.session_id]

    if turn > TURN_LIMIT:
        return JSONResponse(
            status_code=429,
            content={
                "response": (
                    "You have reached the demo chat limit for this session. "
                    "Refresh the page to start a new session."
                ),
                "turn": turn,
                "turn_limit": TURN_LIMIT,
            },
        )

    # ─────────────────────────────────────────────────────────────────────
    # Challenge 01 paste block — replace this stub with real Otto code.
    # The lab instructions tell you exactly what to put between these
    # markers. Until you do, Otto returns a canned not-wired-up response.
    # ─────────────────────────────────────────────────────────────────────
    assistant_text = (
        "Otto isn't wired up yet. Complete Challenge 01 to bring him to life."
    )
    model_id = "(unwired)"
    log.info(
        "chat session=%s tier=%s turn=%d model=%s",
        req.session_id, req.user_tier, turn, model_id,
    )
    # ─── End Challenge 01 paste block ────────────────────────────────────

    return ChatResponse(
        response=assistant_text,
        turn=turn,
        turn_limit=TURN_LIMIT,
        model=model_id,
    )


def _bedrock_user_message(code: Optional[str]) -> str:
    if code in ("ThrottlingException", "ServiceQuotaExceededException"):
        return "Otto is a little overwhelmed right now. Please try again in a few seconds."
    if code == "AccessDeniedException":
        return "Otto can't reach his model — please check AWS credentials and Bedrock model access."
    if code == "ValidationException":
        return "Otto's Config has an invalid setting. Please verify the model ID and variation."
    return "Otto hit an unexpected error. Please try again."


def _extract_text(response: dict) -> str:
    try:
        return response["output"]["message"]["content"][0]["text"]
    except (KeyError, IndexError, TypeError):
        return "Otto received a response in an unexpected format."


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=3333)
