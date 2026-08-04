---
description: "대기열에 쌓인 세션들을 검토해 사고의 흐름을 vault에 반영"
---

대기열 검토. 사용자 대면 텍스트는 한국어.
환경변수 `KC_DIR`가 설정돼 있으면 아래의 `~/.claude/kc`를 그 경로로 대체한다 (훅과 동일 규칙).

1. `~/.claude/kc/config` 없으면 "/kc:init 먼저" 안내 후 중단. `VAULT_PATH`·`AUTHOR`를 읽고
   `$VAULT_PATH/_meta/conventions.md`를 읽는다
2. `~/.claude/kc/queue.tsv`가 없거나 비어 있으면 "검토할 대기열이 없습니다" 후 종료
3. **항목별 처리** (오래된 것부터, 한 번에 하나씩):
   - 열: 시각 TAB session_id TAB cwd TAB 슬러그 TAB transcript경로
   - transcript 경로가 유효하면 그 JSONL에서 사용자·어시스턴트 메시지를 읽어 그 세션에서
     무슨 작업과 결정이 있었는지 파악한다 (파일이 크면 마지막 부분 위주로).
     파일이 없어졌거나 경로가 `-`(수동 보류 항목)이면 사용자에게 그 작업의 기억을 물어본다
   - **중복 확인**: `projects/<슬러그>/context/`에서 해당 날짜 전후의 노트를 보고, 커밋 트리거로
     이미 기록된 내용이면 "이미 기록된 것으로 보입니다"라며 스킵을 제안한다
   - 기록 가치 판단: 의미 있는 사고의 흐름이 없으면 스킵 제안
   - 가치가 있으면 conventions.md 스키마대로 초안 작성(배치 제안, frontmatter·위키링크 쌍,
     비밀정보 제외) → **전문 보여주고 검토받기**
   - 승인 → `status: approved`로 `reference/vault-git-flow.md` 절차대로 반영.
     스킵 → 반영 없이 넘어감
   - **승인이든 스킵이든 처리된 항목은 queue.tsv에서 해당 줄을 제거한다**
     (session_id 기준으로 그 줄만 삭제)
4. 마지막에 요약: 반영 n건, 스킵 m건, 남은 대기열 k건
