#!/bin/bash
# PostToolUse(Bash) 훅: git commit 감지 시 Claude에게 캡처 제안 신호를 보낸다.
# 신호만 보낸다 — API 호출·vault 쓰기 금지. 어떤 경우에도 세션을 막지 않는다(항상 exit 0).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"
PLUGIN_ROOT="$(cd "$HERE/.." && pwd)"

input=$(cat)

CMD=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("tool_input", {}).get("command", "") or "")' 2>/dev/null) || true
CWD=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("cwd", "") or "")' 2>/dev/null) || true

[ -n "${CMD:-}" ] || exit 0
# "git [전역옵션] commit" 형태만 감지 (git log/status, echo commit 등 오탐 방지)
printf '%s' "$CMD" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+((-C|-c)[[:space:]]+[^[:space:]]+[[:space:]]+)*(-[^[:space:]]+[[:space:]]+)*commit([[:space:]]|$)' || exit 0
kc_configured || exit 0

SLUG="$(kc_project_slug "${CWD:-}")"
if [ -n "$SLUG" ]; then
  CTX="[kc] git commit 감지 — 작업이 일단락된 것으로 보임 (프로젝트: $SLUG). $PLUGIN_ROOT/reference/capture-flow.md 를 읽고, 기록 가치가 있으면 그 절차대로 사고의 흐름 기록을 제안하라. 사소한 커밋(오타·포맷 등)이면 아무것도 하지 말고 언급도 하지 말 것."
else
  CTX="[kc] git commit 감지 — 이 repo(${CWD:-알 수 없음})는 kc에 미등록. $PLUGIN_ROOT/reference/capture-flow.md 의 '프로젝트 등록' 절차대로 등록을 제안하고, 등록되면 이어서 기록을 제안하라. 이 세션에서 이미 등록을 거절했다면 다시 제안하지 말 것."
fi

CTX="$CTX" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse",
      "additionalContext": os.environ["CTX"]}}, ensure_ascii=False))'
exit 0
