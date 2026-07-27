---
description: "kc 대기열·vault 동기화 상태 확인 (읽기 전용)"
---

**읽기 전용 명령** — 어떤 파일도 수정하지 않고, 네트워크 접근(fetch/pull/push)도 하지 않는다.
사용자 대면 텍스트는 한국어.

1. `~/.claude/kc/config`가 없으면 "/kc:init을 먼저 실행하세요" 안내 후 중단.
   config에서 `VAULT_PATH`를 읽는다
2. **대기열**: `~/.claude/kc/queue.tsv`의 항목을 표로 정리 (시각을 날짜로 변환, 프로젝트 슬러그 표시).
   항목이 있으면 "`/kc:review`로 검토하세요" 안내
3. **vault git 상태** (`$VAULT_PATH`에서, 네트워크 없이):
   - `git status --porcelain` — 커밋 안 된 변경
   - `git log --oneline @{u}..` — push 안 된 로컬 커밋
   - `git ls-files -u` — 방치된 병합 충돌
   - `.git/rebase-merge` 디렉토리 존재 여부 — 중단된 rebase
4. **draft 노트**: `grep -rl "status: draft" "$VAULT_PATH/projects" "$VAULT_PATH/topics" 2>/dev/null` 개수
5. 한국어로 요약. 문제(밀린 커밋·충돌·중단된 rebase)가 있으면 "`/kc:pull`로 복구할 수 있습니다" 안내
