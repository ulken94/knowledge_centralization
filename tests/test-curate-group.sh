#!/bin/bash
# /kc:curate 그룹 묶음 검사 검증 — 묶이지 않은 형제 프로젝트를 만들어 감지·이동을 확인한다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)/tmp/group-fixture"   # tests/tmp/ 는 .gitignore 대상
rm -rf "$ROOT"; mkdir -p "$ROOT"
git init -q --bare "$ROOT/remote.git"
git clone -q "$ROOT/remote.git" "$ROOT/vault"
V="$ROOT/vault"
git -C "$V" config user.email t@t; git -C "$V" config user.name t

mk() { # $1=슬러그경로 $2=system값(빈문자면 없음)
  mkdir -p "$V/projects/$1/context"
  { echo '---'; echo 'type: project-index'; echo "project: $1"
    [ -n "$2" ] && echo "system: $2"; echo '---'; echo; echo "# ${1##*/}"; } > "$V/projects/$1/_index.md"
  { echo '---'; echo "project: $1"; [ -n "$2" ] && echo "system: $2"
    echo 'date: 2026-08-10'; echo 'topics: [t1]'; echo 'status: approved'; echo '---'
    echo; echo '# 노트'; echo; echo '## 연관'; echo '- 주제: [[t1]]'
    echo "- 프로젝트: [[$1/_index|${1##*/}]]"; } > "$V/projects/$1/context/2026-08-10-노트.md"
}

# 어질러진 상태: 같은 시스템 프로젝트 3개가 평평하게 흩어져 있고 system 키도 없음
mkdir -p "$V/projects" "$V/topics"; touch "$V/projects/.gitkeep" "$V/topics/.gitkeep"
mk "acme-billing-api"   ""
mk "acme-billing-web"   ""
mk "acme-billing-batch" ""
mk "solo-project"       ""          # 형제 없음 → 묶으면 안 됨
git -C "$V" add -A && git -C "$V" commit -qm "픽스처: 묶이지 않은 형제 프로젝트"

echo "=== 정리 전 ==="
find "$V/projects" -name _index.md | sed "s|$V/projects/||;s|/_index.md||" | sort | sed 's/^/  /'

# ── curate 3-d 감지: 접두어가 겹치는 프로젝트가 2개 이상이면 그룹 후보 ──
echo
echo "=== 감지 ==="
# bash 3.2 호환 — mapfile·연관배열 없이 처리한다
SLUGS=$(find "$V/projects" -name _index.md | sed "s|$V/projects/||;s|/_index.md||" | sort)
# 아직 묶이지 않은(슬래시 없는) 슬러그에서 마지막 토큰을 뗀 접두어를 세고, 2건 이상이면 후보
GROUP=$(printf '%s\n' "$SLUGS" | grep -v '/' | sed 's/-[^-]*$//' | sort | uniq -c \
        | awk '$1 >= 2 { print $1, $2 }' | sort -rn | head -1 | awk '{print $2}')
printf '%s\n' "$SLUGS" | grep -v '/' | sed 's/-[^-]*$//' | sort | uniq -c \
  | awk '$1 >= 2 { printf "  그룹 후보: %s (%s건)\n", $2, $1 }'
[ -n "$GROUP" ] || { echo "  후보 없음"; exit 1; }

# ── curate 5단계 적용: mkdir -p → git mv → system 키 → 링크 수정 ──
mkdir -p "$V/projects/$GROUP"
for s in $(printf '%s\n' "$SLUGS" | grep -v '/'); do
  [ "${s#$GROUP-}" != "$s" ] || continue
  new="$GROUP/${s#$GROUP-}"
  git -C "$V" mv "projects/$s" "projects/$new"
  for f in "$V/projects/$new/_index.md" "$V/projects/$new/context/"*.md; do
    python3 - "$f" "$s" "$new" "$GROUP" <<'PY'
import sys,re,pathlib
f,old,new,grp = sys.argv[1:5]
p=pathlib.Path(f); t=p.read_text()
t=t.replace(f"project: {old}", f"project: {new}")
if "\nsystem:" not in t:
    t=re.sub(r"(?m)^(project: .*)$", r"\1\nsystem: "+grp, t, count=1)
t=t.replace(f"[[{old}/_index|", f"[[{new}/_index|")
p.write_text(t)
PY
  done
done
find "$V/projects" -mindepth 1 -type d -empty -delete 2>/dev/null || true
git -C "$V" add -A
git -C "$V" commit -qm "kc: 큐레이션: 폴더 구조 정리 — acme-billing 그룹 묶음"
git -C "$V" push -q origin HEAD

echo
echo "=== 정리 후 ==="
find "$V/projects" -name _index.md | sed "s|$V/projects/||;s|/_index.md||" | sort | sed 's/^/  /'

echo
echo "=== 검증 ==="
p=0; f=0
ck() { if eval "$2"; then p=$((p+1)); echo "PASS: $1"; else f=$((f+1)); echo "FAIL: $1"; fi; }

ck "3개 모두 그룹 아래로"      '[ -f "$V/projects/acme-billing/api/_index.md" ] && [ -f "$V/projects/acme-billing/web/_index.md" ] && [ -f "$V/projects/acme-billing/batch/_index.md" ]'
ck "옛 평평한 경로 사라짐"     '[ ! -d "$V/projects/acme-billing-api" ]'
ck "형제 없는 것은 안 묶임"    '[ -f "$V/projects/solo-project/_index.md" ]'
ck "solo 에 system 키 없음"    '! grep -q "^system:" "$V/projects/solo-project/_index.md"'
ck "_index 에 system 키"       'grep -q "^system: acme-billing$" "$V/projects/acme-billing/api/_index.md"'
ck "노트에도 system 키"        'grep -q "^system: acme-billing$" "$V/projects/acme-billing/api/context/2026-08-10-노트.md"'
ck "project 값이 새 슬러그"    'grep -q "^project: acme-billing/api$" "$V/projects/acme-billing/api/context/2026-08-10-노트.md"'
ck "위키링크 갱신됨"           'grep -q "\[\[acme-billing/api/_index|" "$V/projects/acme-billing/api/context/2026-08-10-노트.md"'
ck "옛 슬러그 링크 잔존 없음"  '! grep -rq "\[\[acme-billing-api/_index" "$V/projects"'
ck "git 이 rename 으로 인식"   'git -C "$V" diff --name-status -M HEAD~1..HEAD | grep -q "^R"'
ck "재귀 탐색이 4개 다 찾음"   '[ "$(find "$V/projects" -name _index.md | wc -l | tr -d " ")" = "4" ]'
ck "system 조회가 3개 프로젝트 6파일" '[ "$(grep -rl "^system: acme-billing$" "$V/projects" | wc -l | tr -d " ")" = "6" ]'
ck ".gitkeep 보존"             '[ -f "$V/projects/.gitkeep" ] && [ -f "$V/topics/.gitkeep" ]'
ck "워킹트리 클린"             '[ -z "$(git -C "$V" status --porcelain)" ]'

echo
echo "pass=$p fail=$f"
[ "$f" -eq 0 ]
