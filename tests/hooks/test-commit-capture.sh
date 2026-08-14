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
# 훅이 경로를 정규화(pwd -P)해 대조하므로 픽스처도 실존하는 정규 경로여야 한다
canon_tmp() { cd "$(mktemp -d)" && pwd -P; }
WORK="$(canon_tmp)"    # 등록 repo
OTHER="$(canon_tmp)"   # 미등록 repo
VAULT="$(canon_tmp)"   # vault
mkdir -p "$VAULT/projects"
printf 'VAULT_PATH=%s\nAUTHOR=t\n' "$VAULT" > "$KC_DIR/config"
printf '%s\tproj-a\n' "$WORK" > "$KC_DIR/projects.tsv"

expect_match  "등록 repo의 git commit → 신호"        "$(json "$WORK" 'git commit -m x')" "additionalContext"
expect_match  "등록 repo 신호에 슬러그 포함"          "$(json "$WORK" 'git commit -m x')" "proj-a"
expect_match  "git -C 대상 repo 기준으로 판정"        "$(json "$OTHER" "git -C $WORK commit -m x")" "proj-a"
expect_match  "미등록 repo → 등록 제안 신호"          "$(json "$OTHER" 'git commit -m x')" "미등록"
expect_silent "commit 아님(git status)"               "$(json "$WORK" 'git status')"
expect_silent "git 없는 commit 단어(echo commit)"     "$(json "$WORK" 'echo commit')"
expect_silent "JSON 아닌 입력"                        "notjson"
expect_silent "vault 자체 커밋(git -C vault)은 침묵"  "$(json "$WORK" "git -C $VAULT commit -m x")"
expect_silent "vault 하위 경로 커밋도 침묵"           "$(json "$WORK" "git -C $VAULT/projects commit -m x")"
expect_silent "cwd가 vault면 침묵"                    "$(json "$VAULT" 'git commit -m x')"
expect_silent "존재하지 않는 -C 경로면 침묵"          "$(json "$WORK" 'git -C /no/such/dir commit -m x')"

# git worktree: 경로가 달라도 주 워크트리 기준으로 같은 프로젝트여야 한다
git -C "$WORK" init -q 2>/dev/null
git -C "$WORK" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null
git -C "$WORK" worktree add -q -b wt "$WORK-wt" 2>/dev/null
WT="$(cd "$WORK-wt" && pwd -P)"
expect_match  "등록 repo의 워크트리 → 같은 슬러그"    "$(json "$WT" 'git commit -m x')" "proj-a"
expect_match  "워크트리에서 git -C 주 repo"           "$(json "$WT" "git -C $WORK commit -m x")" "proj-a"

git -C "$OTHER" init -q 2>/dev/null
git -C "$OTHER" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init 2>/dev/null
git -C "$OTHER" worktree add -q -b wt "$OTHER-wt" 2>/dev/null
OWT="$(cd "$OTHER-wt" && pwd -P)"
expect_match  "미등록 워크트리 → 주 워크트리로 등록 제안" "$(json "$OWT" 'git commit -m x')" "$OTHER)"

rm "$KC_DIR/config"
expect_silent "kc 미설정이면 침묵"                    "$(json "$WORK" 'git commit -m x')"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
