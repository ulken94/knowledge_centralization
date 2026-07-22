#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../../hooks/commit-capture.sh"
pass=0; fail=0

expect_match() { # $1=이름 $2=JSON입력 $3=출력에 포함돼야 할 문자열
  out=$(printf '%s' "$2" | "$SCRIPT" 2>/dev/null)
  if printf '%s' "$out" | grep -q "$3"; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (out=$out)"; fi
}
expect_silent() { # $1=이름 $2=JSON입력
  out=$(printf '%s' "$2" | "$SCRIPT" 2>/dev/null)
  if [ -z "$out" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (out=$out)"; fi
}
json() { printf '{"cwd":"%s","tool_input":{"command":"%s"}}' "$1" "$2"; }

[ -x "$SCRIPT" ] || { echo "FAIL: hooks/commit-capture.sh 없거나 실행권한 없음"; exit 1; }
export KC_DIR="$(mktemp -d)"
printf 'VAULT_PATH=/tmp/v\nAUTHOR=t\n' > "$KC_DIR/config"
printf '/repo/a\tproj-a\n' > "$KC_DIR/projects.tsv"

expect_match  "등록 repo의 git commit → 신호"        "$(json /repo/a 'git commit -m x')" "additionalContext"
expect_match  "등록 repo 신호에 슬러그 포함"          "$(json /repo/a 'git commit -m x')" "proj-a"
expect_match  "git -C 형태도 감지"                    "$(json /repo/a 'git -C /repo/a commit -m x')" "additionalContext"
expect_match  "미등록 repo → 등록 제안 신호"          "$(json /other 'git commit -m x')" "미등록"
expect_silent "commit 아님(git status)"               "$(json /repo/a 'git status')"
expect_silent "git 없는 commit 단어(echo commit)"     "$(json /repo/a 'echo commit')"
expect_silent "JSON 아닌 입력"                        "notjson"

rm "$KC_DIR/config"
expect_silent "kc 미설정이면 침묵"                    "$(json /repo/a 'git commit -m x')"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
