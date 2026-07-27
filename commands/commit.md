---
description: "코드 밖 작업(PPT·문서 등)의 사고의 흐름을 vault에 기록"
argument-hint: "[작업 한 줄 설명]"
---

수동 컨텍스트 기록. 사용자 대면 텍스트는 전부 한국어.

## 사전 확인

- `~/.claude/kc/config`가 없으면 "먼저 `/kc:init`을 실행하세요"라고 안내하고 중단
- config에서 `VAULT_PATH`·`AUTHOR`를 읽고, `$VAULT_PATH/_meta/conventions.md`를 읽어
  스키마·배치 기준·링크 규칙을 따른다

## 인터뷰 (한 번에 한 질문씩)

`$ARGUMENTS`가 있으면 그것을 출발점으로 삼는다.

1. 무슨 작업이었나요? (어떤 산출물·어떤 목적)
2. 어떤 대안들을 검토했나요?
3. 왜 그렇게 결정했나요?
4. 막힌 것·미해결로 남은 것은요?

사용자가 Claude 앱 등 다른 곳의 대화 내용을 붙여넣으면 인터뷰를 생략하고
그 내용에서 위 항목들을 추출한다. 부족한 항목만 추가 질문한다.

## 노트 작성·반영

- conventions.md 스키마대로 초안 작성: frontmatter(`author`는 config의 AUTHOR,
  `date`는 오늘, `status: draft`)와 `## 연관` 위키링크를 쌍으로
- 배치 판단·제안: 프로젝트 종속 → `projects/<슬러그>/context/YYYY-MM-DD-<주제>.md`,
  범용 지식 → `topics/<주제>.md` (출처 프로젝트 링크는 남김).
  어느 프로젝트인지 애매하면 vault의 `projects/` 목록을 보여주고 고르게 한다
- 비밀정보(자격증명·비밀키·내부 URL)는 포함하지 않는다
- **초안 전문을 보여주고 검토받는다.** 승인(수정 반영 포함) 시 `status: approved`로 바꾸고
  이 플러그인의 `reference/vault-git-flow.md` 절차대로 커밋 & push. 거절 시 아무것도 쓰지 않는다
