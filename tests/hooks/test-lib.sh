#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LIB="$HERE/../../hooks/lib.sh"
pass=0; fail=0
t() { # $1=이름 $2=기대값 $3=실제값
  if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1 (기대='$2' 실제='$3')"; fi
}

[ -f "$LIB" ] || { echo "FAIL: hooks/lib.sh 없음"; exit 1; }
export KC_DIR="$(mktemp -d)"
source "$LIB"

# 미설정 상태
if kc_configured; then t "미설정 감지" "no" "yes"; else t "미설정 감지" "no" "no"; fi

printf 'VAULT_PATH=/tmp/v\nAUTHOR=t\nTOKEN=a=b\n' > "$KC_DIR/config"
if kc_configured; then t "설정 감지" "yes" "yes"; else t "설정 감지" "yes" "no"; fi

t "config_get: 값 읽기" "/tmp/v" "$(kc_config_get VAULT_PATH)"
t "config_get: 없는 키 → 빈 값" "" "$(kc_config_get NOPE)"
t "config_get: 값에 = 포함" "a=b" "$(kc_config_get TOKEN)"

REAL="$(cd "$(mktemp -d)" && pwd -P)"
ln -s "$REAL" "$KC_DIR/link"
t "canonical: 실존 경로" "$REAL" "$(kc_canonical "$REAL")"
t "canonical: 심볼릭 링크 해소" "$REAL" "$(kc_canonical "$KC_DIR/link")"
t "canonical: 비실존 경로 → 빈 값" "" "$(kc_canonical /no/such/path)"

printf '/Users/a/repo\tmy-proj\n' > "$KC_DIR/projects.tsv"
t "슬러그: 경로 정확히 일치" "my-proj" "$(kc_project_slug /Users/a/repo)"
t "슬러그: 하위 디렉토리" "my-proj" "$(kc_project_slug /Users/a/repo/src/x)"
t "슬러그: 접두어 오탐 없음" "" "$(kc_project_slug /Users/a/repository)"
t "슬러그: 미등록" "" "$(kc_project_slug /Users/b/other)"

printf '1\ts-abc\t/x\tp\t-\n' > "$KC_DIR/queue.tsv"
if kc_in_queue s-abc; then t "대기열: 존재" "yes" "yes"; else t "대기열: 존재" "yes" "no"; fi
if kc_in_queue s-zzz; then t "대기열: 부재" "no" "yes"; else t "대기열: 부재" "no" "no"; fi

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
