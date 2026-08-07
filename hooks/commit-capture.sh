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

# 커밋 대상 repo를 정한다: `git -C <경로> commit`이면 그 경로, 아니면 세션 cwd.
# (cwd로만 판단하면 kc 자신의 vault 쓰기가 세션 repo의 작업 커밋으로 오인된다)
TARGET=$(printf '%s' "$CMD" | sed -nE 's/.*(^|[;&|[:space:]])git[[:space:]]+.*-C[[:space:]]+("([^"]*)"|'"'"'([^'"'"']*)'"'"'|([^[:space:]]+)).*/\3\4\5/p' | head -n1)
[ -n "${TARGET:-}" ] || TARGET="${CWD:-}"
TARGET="$(kc_canonical "$TARGET")"
[ -n "${TARGET:-}" ] || exit 0

# vault 자체에 대한 커밋은 kc가 만든 것이므로 캡처 대상이 아니다 — 조용히 종료
VAULT="$(kc_canonical "$(kc_config_get VAULT_PATH)")"
if [ -n "${VAULT:-}" ] && { [ "$TARGET" = "$VAULT" ] || case "$TARGET" in "$VAULT"/*) true ;; *) false ;; esac; }; then
  exit 0
fi

SLUG="$(kc_project_slug "$TARGET")"
if [ -n "$SLUG" ]; then
  CTX="[kc] git commit 감지 — 작업이 일단락된 것으로 보임 (프로젝트: $SLUG). $PLUGIN_ROOT/reference/capture-flow.md 를 읽고, 기록 가치가 있으면 그 절차대로 사고의 흐름 기록을 제안하라. 사소한 커밋(오타·포맷 등)이면 아무것도 하지 말고 언급도 하지 말 것."
else
  CTX="[kc] git commit 감지 — 이 repo($TARGET)는 kc에 미등록. $PLUGIN_ROOT/reference/capture-flow.md 의 '프로젝트 등록' 절차대로 등록을 제안하고, 등록되면 이어서 기록을 제안하라. 이 세션에서 이미 등록을 거절했다면 다시 제안하지 말 것."
fi

CTX="$CTX" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse",
      "additionalContext": os.environ["CTX"]}}, ensure_ascii=False))'
exit 0
