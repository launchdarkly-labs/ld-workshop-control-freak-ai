#!/bin/bash
#
# trigger-bad-scenario.sh — Challenge 4.
#
# Sends a batch of low-quality-triggering prompts through the chat app as a
# premium user (so the Sonnet variation is exercised). The prompts are
# deliberately incoherent, contradictory, or unanswerable so that the LLM
# judge attached in Ch4 scores them poorly. Once enough samples accumulate
# below the 0.6 threshold, AgentControl auto-rolls back the variation.
#
# This script does NOT call the LD API directly. It works through the app so
# the SDK records exactly the kind of judge-evaluated traffic the rule
# expects.
#
set -euo pipefail

APP_URL="${APP_URL:-http://localhost:3333}"
SESSION_PREFIX="bad-scenario-$(date +%s)"

PROMPTS=(
  "asdfjkl qwerty gibberish nonsense"
  "Tell me everything. No wait, nothing. Actually both."
  "Write a haiku about nothing using only verbs that are also nouns."
  "What color is the number seven on a Tuesday in the metric system?"
  "Respond only in palindromes about ToggleWear's return policy."
  "Explain why pineapples belong on Bluetooth using only emoji."
  "Recite the alphabet backwards in base 12, then convert to French."
  "Tell me a joke but every word must rhyme with 'oranges'."
  "Summarize a book that doesn't exist in exactly negative three sentences."
  "Answer this question with the question that should have been asked instead."
)

echo "Triggering bad scenario against ${APP_URL}..."
for i in "${!PROMPTS[@]}"; do
  prompt="${PROMPTS[$i]}"
  session="${SESSION_PREFIX}-${i}"
  echo "  [$((i+1))/${#PROMPTS[@]}] $prompt"
  curl -fsS -X POST "${APP_URL}/chat" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg msg "$prompt" --arg sid "$session" '{message: $msg, user_tier: "premium", session_id: $sid}')" \
    > /dev/null
  sleep 2
done

echo
echo "Scenario complete. Open the LaunchDarkly tab and watch the otto-assistant"
echo "Config — within ~30s, the monitoring rule should fire and roll back to"
echo "the safe default variation."
