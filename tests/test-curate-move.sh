#!/bin/bash
# /kc:curate 폴더 구조 정리(5단계)의 이동 메커니즘 검증 — 어질러진 vault를 만들어 실제로 수행한다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)/tmp/curate-fixture"   # tests/tmp/ 는 .gitignore 대상
rm -rf "$ROOT"; mkdir -p "$ROOT"
git init -q --bare "$ROOT/remote.git"
git clone -q "$ROOT/remote.git" "$ROOT/vault"
V="$ROOT/vault"
git -C "$V" config user.email t@t; git -C "$V" config user.name t

# ── 어질러진 상태 만들기 ────────────────────────────────────────────
mkdir -p "$V/projects/alpha/context" "$V/projects/beta/context" "$V/topics" "$V/inbox"
touch "$V/projects/.gitkeep" "$V/topics/.gitkeep"

# (1) 범용 지식인데 projects/ 아래 있음 → topics/ 로 이동 대상
cat > "$V/projects/alpha/context/2026-08-01-공통-지식.md" <<'EOF'
---
project: alpha
topics: [공통-지식]
---
# 공통 지식
## 연관
- 프로젝트: [[alpha/_index|alpha]]
EOF

# (2) alpha/_index.md 가 위 노트를 위키링크로 가리킴 → 이동하면 깨진다
cat > "$V/projects/alpha/_index.md" <<'EOF'
---
type: project-index
project: alpha
---
# alpha
## 주요 결정
- [[2026-08-01-공통-지식]] — 이동하면 깨질 링크
EOF

# (3) 파일명 규칙 위반 (YYYY-MM-DD- 없음)
cat > "$V/projects/beta/context/노트.md" <<'EOF'
---
project: beta
date: 2026-08-02
---
# 베타 작업 기록
EOF

git -C "$V" add -A && git -C "$V" commit -qm "픽스처: 어질러진 vault"

# (4) 추적 안 된 inbox 메모 (git mv 불가 → mv + git add 경로)
cat > "$V/inbox/메모.md" <<'EOF'
# 대충 적은 메모
베타 관련 내용
EOF

echo "=== 정리 전 ==="
(cd "$V" && find . -path ./.git -prune -o -type f -print | sort)
BEFORE=$(git -C "$V" rev-parse HEAD)

# ── curate 5단계 절차 그대로 수행 ──────────────────────────────────
# a) 대상 디렉토리 먼저 생성 (git mv는 대상 디렉토리 없으면 실패)
mkdir -p "$V/topics" "$V/projects/beta/context"
# b) 추적 파일은 git mv
git -C "$V" mv "projects/alpha/context/2026-08-01-공통-지식.md" "topics/공통-지식.md"
git -C "$V" mv "projects/beta/context/노트.md" "projects/beta/context/2026-08-02-노트.md"
# c) 추적 안 된 파일은 mv 후 git add
mkdir -p "$V/projects/beta/context"
mv "$V/inbox/메모.md" "$V/projects/beta/context/2026-08-06-메모.md"
git -C "$V" add "projects/beta/context/2026-08-06-메모.md"
# d) 이동으로 깨진 위키링크를 같은 커밋에서 수정
perl -i -pe 's/\[\[2026-08-01-공통-지식\]\]/[[공통-지식]]/' "$V/projects/alpha/_index.md"
git -C "$V" add "projects/alpha/_index.md"
# e) _index.md 없는 프로젝트 보충
cat > "$V/projects/beta/_index.md" <<'EOF'
---
type: project-index
project: beta
---
# beta
## 주요 결정
EOF
git -C "$V" add "projects/beta/_index.md"

git -C "$V" commit -qm "kc: 큐레이션: 폴더 구조 정리"
git -C "$V" push -q origin HEAD

# f) 비게 된 하위 디렉토리 정리 — 구조 디렉토리는 제외 (로컬 위생 작업, 커밋 무관)
(cd "$V" && find projects topics -mindepth 1 -type d -empty -delete 2>/dev/null) || true

echo
echo "=== 정리 후 ==="
(cd "$V" && find . -path ./.git -prune -o -type f -print | sort)

# ── 검증 ───────────────────────────────────────────────────────────
echo
echo "=== 검증 ==="
p=0; f=0
ck() { if eval "$2"; then p=$((p+1)); echo "PASS: $1"; else f=$((f+1)); echo "FAIL: $1"; fi; }

ck "범용 노트가 topics/ 로 이동" '[ -f "$V/topics/공통-지식.md" ]'
ck "원래 위치는 비었음"          '[ ! -f "$V/projects/alpha/context/2026-08-01-공통-지식.md" ]'
ck "파일명 규칙 교정됨"          '[ -f "$V/projects/beta/context/2026-08-02-노트.md" ]'
ck "inbox 메모가 정식 위치로"    '[ -f "$V/projects/beta/context/2026-08-06-메모.md" ]'
ck "inbox 원본 사라짐"           '[ ! -f "$V/inbox/메모.md" ]'
ck "빠졌던 _index.md 생성"       '[ -f "$V/projects/beta/_index.md" ]'
ck "깨질 링크가 수정됨"          'grep -q "\[\[공통-지식\]\]" "$V/projects/alpha/_index.md"'
ck "옛 링크 잔존 없음"           '! grep -q "\[\[2026-08-01-공통-지식\]\]" "$V/projects/alpha/_index.md"'
ck ".gitkeep 보존"               '[ -f "$V/projects/.gitkeep" ] && [ -f "$V/topics/.gitkeep" ]'
ck "git이 rename으로 인식"       'git -C "$V" diff --name-status -M "$BEFORE"..HEAD | grep -q "^R"'
ck "이동과 링크수정이 같은 커밋" 'git -C "$V" show --stat --oneline HEAD | grep -q "alpha/_index.md"'
ck "워킹트리 클린"               '[ -z "$(git -C "$V" status --porcelain)" ]'
ck "push 완료(밀린 커밋 없음)"   '[ -z "$(git -C "$V" log --oneline @{u}..)" ]'
ck "빈 하위 디렉토리 정리됨"     '[ ! -d "$V/projects/alpha/context" ]'
ck "구조 디렉토리 inbox/ 보존"   '[ -d "$V/inbox" ]'
ck "구조 디렉토리 topics/ 보존"  '[ -d "$V/topics" ]'
ck "정리가 커밋에 영향 없음"     '[ -z "$(git -C "$V" status --porcelain)" ]'

echo
echo "=== 이 커밋의 변경 (rename 감지) ==="
git -C "$V" diff --name-status -M "$BEFORE"..HEAD
echo
echo "pass=$p fail=$f"
[ "$f" -eq 0 ]
