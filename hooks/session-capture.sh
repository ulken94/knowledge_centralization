#!/bin/bash
# SessionEnd 훅: 등록 프로젝트의 세션을 대기열에 등록만 한다 (안전망).
# API 호출·vault 쓰기 금지. 항상 exit 0.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/lib.sh"

input=$(cat)
line=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print("\t".join([d.get("session_id", "") or "",
                 d.get("cwd", "") or "",
                 d.get("transcript_path", "") or ""]))' 2>/dev/null) || exit 0
[ -n "$line" ] || exit 0
SESSION_ID=$(printf '%s' "$line" | cut -f1)
CWD=$(printf '%s' "$line" | cut -f2)
TRANSCRIPT=$(printf '%s' "$line" | cut -f3)

kc_configured || exit 0
[ -n "$SESSION_ID" ] || exit 0
SLUG="$(kc_project_slug "$CWD")"
[ -n "$SLUG" ] || exit 0
kc_in_queue "$SESSION_ID" && exit 0

mkdir -p "$KC_DIR"
printf '%s\t%s\t%s\t%s\t%s\n' "$(date +%s)" "$SESSION_ID" "$CWD" "$SLUG" "${TRANSCRIPT:--}" >> "$KC_QUEUE"
exit 0
