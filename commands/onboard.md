---
description: "프로젝트 온보딩 브리핑 — 새 팀원의 soft landing"
argument-hint: "<프로젝트-슬러그>"
---

새 팀원(또는 오랜만에 돌아온 팀원)을 위한 프로젝트 브리핑. 사용자 대면 텍스트는 한국어.

1. `~/.claude/kc/config` 없으면 "/kc:init 먼저" 안내 후 중단. `VAULT_PATH` 읽기
2. 먼저 최신화: `git -C "$VAULT_PATH" pull --rebase`
   (충돌 등 문제 시 `reference/vault-git-flow.md` 예외 처리 절차)
3. `$ARGUMENTS`의 슬러그가 없거나 `projects/`에 존재하지 않으면, `projects/` 하위 목록을
   각 `_index.md`의 "목적" 첫 줄과 함께 보여주고 고르게 한다
4. 읽기: `projects/<슬러그>/_index.md` → `context/`의 노트 전체(파일명 날짜순) →
   노트들의 `## 연관`이 가리키는 topic 노트들
5. **브리핑** (한국어, 아래 순서):
   ① 프로젝트 배경 — 왜 시작됐고 누구를 위한 것인지
   ② 주요 결정 타임라인 — 무엇을, 왜 그렇게 결정했는지 (사고의 흐름 요약)
   ③ 현재 상태와 미해결 사항
   ④ 연관 프로젝트·주제 — topic 허브 기준으로
   ⑤ 추천 읽기 순서 — vault 상대경로로 노트를 나열 (예: `projects/x/context/2026-07-20-....md`)
6. 마무리: "더 궁금한 건 이 자리에서 바로 물어보세요"라고 안내하고 후속 질문을 받는다
