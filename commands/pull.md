---
description: "최신 vault 받아오기 + 새로 올라온 컨텍스트 브리핑, 꼬인 상태 복구"
---

사용자 대면 텍스트는 한국어.
환경변수 `KC_DIR`가 설정돼 있으면 아래의 `~/.claude/kc`를 그 경로로 대체한다 (훅과 동일 규칙).
승인·선택을 물을 때는 이 플러그인의 `reference/asking.md`를 따른다 — 평문으로 묻지 말고 선택지로 고르게 한다.

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
6. **conventions 갱신 제안**: 플러그인이 업데이트되면서 새 규칙이 생겼는데 vault의 사본이
   낡아 있을 수 있다. 플러그인 템플릿과 vault 사본을 비교한다 —
   `$CLAUDE_PLUGIN_ROOT/templates/conventions.md` (환경변수가 없으면 `~/.claude/plugins`
   아래에서 kc 플러그인 디렉토리를 찾는다) vs `$VAULT_PATH/_meta/conventions.md`.
   - 같으면 아무 말도 하지 않는다
   - 다르면 차이를 두 방향으로 나눠서 보여준다:
     **(가) 플러그인에만 있는 규칙** — 플러그인 업데이트로 추가된 것. 갱신 후보
     **(나) vault에만 있는 규칙** — 팀이 직접 고친 것. **절대 건드리지 않는다**
   - `conventions.md`는 vault 쪽 SSOT다. **템플릿으로 통째 덮어쓰지 않는다** —
     (가)의 항목만 골라 vault 사본에 더하는 안을 제안하고, 항목별로 승인받는다
   - 승인된 것만 반영 → 커밋 메시지 `kc: conventions 규칙 갱신: <요약>`으로
     커밋 & push (vault-git-flow.md 절차)
   - 거절하면 이 세션에서 다시 묻지 않는다
