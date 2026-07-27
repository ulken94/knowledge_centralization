---
description: "최신 vault 받아오기 + 새로 올라온 컨텍스트 브리핑, 꼬인 상태 복구"
---

사용자 대면 텍스트는 한국어.

1. `~/.claude/kc/config`가 없으면 "/kc:init을 먼저 실행하세요" 안내 후 중단.
   `VAULT_PATH`를 읽는다
2. 현재 위치 기록: `OLD=$(git -C "$VAULT_PATH" rev-parse HEAD)`
3. 꼬인 상태 먼저 처리:
   - 중단된 rebase(`.git/rebase-merge` 존재)나 충돌(`git ls-files -u` 출력)이 있으면
     이 플러그인의 `reference/vault-git-flow.md` 예외 처리 절차대로 해결 (사용자 확인 포함)
   - push 안 된 커밋(`git log --oneline @{u}..`)이 있으면 `git push` 먼저 시도
4. `git -C "$VAULT_PATH" pull --rebase` — 충돌 시 vault-git-flow.md 예외 처리 절차
5. **새 컨텍스트 브리핑**: `git -C "$VAULT_PATH" diff --name-status $OLD..HEAD`로 추가·수정된
   노트를 파악하고, 추가된 컨텍스트 노트를 읽어 "누가(작성자) 어느 프로젝트에 무슨 맥락을
   남겼는지"를 한국어로 요약한다. 변경이 없으면 "vault는 이미 최신 상태입니다" 한 줄로 끝
