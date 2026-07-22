#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../../hooks/session-capture.sh"
pass=0; fail=0
t() { if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (기대='$2' 실제='$3')"; fi }
json() { printf '{"session_id":"%s","cwd":"%s","transcript_path":"%s"}' "$1" "$2" "$3"; }

[ -x "$SCRIPT" ] || { echo "FAIL: hooks/session-capture.sh 없거나 실행권한 없음"; exit 1; }
export KC_DIR="$(mktemp -d)"
Q="$KC_DIR/queue.tsv"
printf 'VAULT_PATH=/tmp/v\nAUTHOR=t\n' > "$KC_DIR/config"
printf '/repo/a\tproj-a\n' > "$KC_DIR/projects.tsv"

printf '%s' "$(json s-1 /repo/a /tmp/t1.jsonl)" | "$SCRIPT"
t "등록 프로젝트 세션 → 대기열 1건" "1" "$(wc -l < "$Q" | tr -d ' ')"
t "대기열 줄에 슬러그·transcript 기록" "proj-a" "$(awk -F'\t' 'NR==1{print $4}' "$Q")"

printf '%s' "$(json s-1 /repo/a /tmp/t1.jsonl)" | "$SCRIPT"
t "같은 session_id 중복 등록 안 함" "1" "$(wc -l < "$Q" | tr -d ' ')"

printf '%s' "$(json s-2 /elsewhere /tmp/t2.jsonl)" | "$SCRIPT"
t "미등록 디렉토리 세션은 무시" "1" "$(wc -l < "$Q" | tr -d ' ')"

rm "$KC_DIR/config"
printf '%s' "$(json s-3 /repo/a /tmp/t3.jsonl)" | "$SCRIPT"
t "kc 미설정이면 무시" "1" "$(wc -l < "$Q" | tr -d ' ')"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
