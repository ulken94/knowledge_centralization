# Vault 쓰기 공통 절차 (git flow)

vault에 노트를 쓰는 모든 동작은 이 절차를 따른다. 사용자가 git 명령을 직접 다루게 하지 않는다.
아래에서 `$VAULT_PATH`는 `~/.claude/kc/config`의 값. 순수 git만 사용한다 (gh 금지).
(환경변수 `KC_DIR`가 설정돼 있으면 config 위치는 `$KC_DIR/config` — 훅과 동일 규칙.)

## 절차

1. 밀린 커밋 확인: `git -C "$VAULT_PATH" log --oneline @{u}..` 출력이 있으면 먼저 `git -C "$VAULT_PATH" push` 시도
2. `git -C "$VAULT_PATH" pull --rebase`
3. 노트 생성/수정 — **반드시 사용자 검토·승인을 거친 내용만**
4. `git -C "$VAULT_PATH" add <파일들>` 후 커밋. 메시지 형식(한국어):
   `kc: <프로젝트슬러그|topics|큐레이션>: <무슨 컨텍스트인지 한 줄>`
5. `git -C "$VAULT_PATH" push`

## 예외 처리

- **이미 워킹트리에 변경이 있는 경우**: 위 순서는 pull 후 쓰기를 전제하지만, 실제로는
  노트를 먼저 쓰고 절차를 타는 일이 잦다. 그 상태로 2단계를 실행하면
  `cannot pull with rebase: You have unstaged changes`로 멈춘다.
  `git -C "$VAULT_PATH" fetch origin` 후 `git -C "$VAULT_PATH" log --oneline HEAD..@{u}`로
  원격에 새 커밋이 있는지 본다 — 없으면 2단계를 건너뛰고 4단계로 간다.
  있으면 `git -C "$VAULT_PATH" stash` → pull --rebase → `stash pop` 순으로 처리한다
- **pull --rebase 충돌**: 충돌 파일을 열어 양쪽 의도를 모두 보존하는 병합을 시도한다.
  컨텍스트 노트는 append 위주라 대부분 양쪽 내용을 다 살리면 된다.
  판단이 애매하면 양쪽 버전을 사용자에게 보여주고 물어본다 — **조용히 한쪽을 버리지 않는다**.
  해결 후 `git -C "$VAULT_PATH" add <해결파일>` → `git -C "$VAULT_PATH" rebase --continue`
- **push 실패(네트워크 등)**: "커밋은 로컬에 안전하게 남아 있고, 다음 kc 명령이 자동으로
  push를 재시도한다"고 사용자에게 알리고 정상 종료한다
