---
description: "kc 최초 설정 (머신당 1회) — 팀 vault clone + 로컬 설정 생성"
argument-hint: "[vault git URL]"
---

kc 플러그인의 최초 설정을 진행한다. 사용자 대면 텍스트는 전부 한국어.

## 사전 확인

`~/.claude/kc/config`가 이미 있으면 현재 설정(VAULT_PATH, AUTHOR)을 보여주고
"재설정할까요?"를 물은 뒤, 원할 때만 계속한다.

## 절차

1. **vault git URL**: `$ARGUMENTS`에 있으면 사용, 없으면 물어본다.
   self-hosted git URL이다 — 이후 모든 조작은 순수 git 명령만 사용한다 (gh 금지)
2. **clone 위치**: 물어본다 (기본값 제안: `~/team-vault`).
   - 그 경로가 이미 같은 remote의 clone이면 clone 생략하고 그대로 사용
   - 아니면 `git clone <URL> <경로>` 실행
3. **작성자 이름**: `git config user.name` 값을 기본값으로 제안하고 확인받는다
4. **스켈레톤 부트스트랩**: clone된 vault에 `_meta/conventions.md`가 없으면(새 vault) 생성한다.
   플러그인 설치 경로를 `$CLAUDE_PLUGIN_ROOT` 환경변수에서 얻는다
   (없으면 `~/.claude/plugins` 아래에서 kc 플러그인 디렉토리를 찾는다):
   - 디렉토리 생성: `projects/`, `topics/`, `inbox/`, `_meta/templates/`
     (빈 디렉토리 유지용으로 `projects/.gitkeep`, `topics/.gitkeep` 추가)
   - 복사: `templates/conventions.md` → `_meta/conventions.md`,
     `templates/project-index.md`·`context-note.md`·`topic.md` → `_meta/templates/`,
     `templates/inbox-README.md` → `inbox/README.md`
   - 부트스트랩 내용을 사용자에게 보여주고 확인받은 뒤
     커밋 메시지 `kc: vault 스켈레톤 초기화`로 커밋 & push
5. **로컬 설정 생성**:
   ```bash
   mkdir -p ~/.claude/kc
   cat > ~/.claude/kc/config <<EOF
   VAULT_PATH=<clone 절대경로>
   AUTHOR=<이름>
   EOF
   touch ~/.claude/kc/projects.tsv
   ```
6. **완료 안내**: vault 경로를 요약하고 다음을 알려준다 —
   "이제 평소처럼 일하면 됩니다. 프로젝트 repo에서 커밋하면 기록을 제안하고(첫 커밋 때
   프로젝트 등록도 그때 제안), 코드 밖 작업은 `/kc:commit`, 프로젝트 파악은 `/kc:onboard`."
