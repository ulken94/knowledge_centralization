#!/bin/bash
# E2E용 샘플 vault 생성: bare remote + clone + 샘플 데이터. clone 경로를 echo.
set -euo pipefail
ROOT="${1:?사용법: make-sample-vault.sh <디렉토리>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
rm -rf "$ROOT"; mkdir -p "$ROOT"; ROOT="$(cd "$ROOT" && pwd)"

git init --bare -q "$ROOT/vault-remote.git"
git clone -q "$ROOT/vault-remote.git" "$ROOT/vault" 2>/dev/null
cd "$ROOT/vault"

mkdir -p projects/video-pipeline/context projects/cctv-monitor/context topics inbox _meta/templates
cp "$HERE/../templates/conventions.md" _meta/conventions.md
cp "$HERE/../templates/project-index.md" "$HERE/../templates/context-note.md" "$HERE/../templates/topic.md" _meta/templates/
cp "$HERE/../templates/inbox-README.md" inbox/README.md

cat > projects/video-pipeline/_index.md <<'EOF'
---
type: project-index
project: video-pipeline
---

# video-pipeline

## 목적
클라이언트사 영상 처리 파이프라인 구축

## 현재 상태
프로토콜 선정 완료, 구현 진행 중

## 주요 결정
- [[2026-07-20-스트리밍-프로토콜-선택]]

## 관련 주제
- [[영상-스트리밍]]
EOF

cat > projects/video-pipeline/context/2026-07-20-스트리밍-프로토콜-선택.md <<'EOF'
---
project: video-pipeline
date: 2026-07-20
author: haneol
type: decision
topics: [영상-스트리밍]
status: approved
---

# 스트리밍 프로토콜 선택

## 배경
클라이언트사 요구는 브라우저 재생 + 5초 이내 지연.

## 사고의 흐름
- WebRTC를 먼저 검토 — 지연은 최소지만 서버 인프라 복잡도가 과함
- HLS는 표준 지연이 10초 이상이라 요구 미달 → LL-HLS로 재검토

## 결론
LL-HLS 채택. 브라우저 호환성과 지연 요구를 동시에 만족.

## 다음 단계 · 미해결
- 세그먼트 길이 튜닝 미완

## 연관
- 주제: [[영상-스트리밍]]
- 프로젝트: [[video-pipeline/_index|video-pipeline]]
- 관련 노트:
EOF

cat > projects/cctv-monitor/_index.md <<'EOF'
---
type: project-index
project: cctv-monitor
---

# cctv-monitor

## 목적
사내 CCTV 통합 모니터링

## 현재 상태
저지연 요구 검토 단계

## 주요 결정

## 관련 주제
- [[영상-스트리밍]]
EOF

cat > projects/cctv-monitor/context/2026-07-21-저지연-요구-검토.md <<'EOF'
---
project: cctv-monitor
date: 2026-07-21
author: haneol
type: exploration
topics: [영상-스트리밍]
status: draft
---

# 저지연 요구 검토

## 배경
관제실에서 1초 이내 반응이 필요하다는 요구.

## 사고의 흐름
- video-pipeline의 LL-HLS 경험을 참고했으나 1초 요구에는 부족해 보임
- WebRTC 재검토 필요

## 결론
(미정)

## 다음 단계 · 미해결
- WebRTC 인프라 비용 조사

## 연관
- 주제: [[영상-스트리밍]]
- 프로젝트: [[cctv-monitor/_index|cctv-monitor]]
- 관련 노트: [[2026-07-20-스트리밍-프로토콜-선택]]
EOF

cat > topics/영상-스트리밍.md <<'EOF'
---
type: topic
---

# 영상 스트리밍

## 정리된 지식

## 관련 프로젝트·노트
- [[video-pipeline/_index|video-pipeline]] — [[2026-07-20-스트리밍-프로토콜-선택]]
- [[cctv-monitor/_index|cctv-monitor]] — [[2026-07-21-저지연-요구-검토]]
EOF

cat > inbox/회의메모-0722.md <<'EOF'
오늘 클라이언트 미팅. 다음 분기에 모바일 앱에서도 영상 봐야 한다고 함.
LL-HLS면 iOS는 그냥 되는데 안드로이드 웹뷰는 확인 필요하다고 답했음.
EOF

git add -A
git -c user.name=sample -c user.email=sample@test commit -qm "kc: 샘플 vault 데이터"
git push -q
echo "$ROOT/vault"
