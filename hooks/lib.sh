#!/bin/bash
# kc 훅·명령 공통 — 로컬 상태 파일 경로와 조회 함수. 외부 의존성 없음.

KC_DIR="${KC_DIR:-$HOME/.claude/kc}"
KC_CONFIG="$KC_DIR/config"          # KEY=VALUE (VAULT_PATH, AUTHOR)
KC_PROJECTS="$KC_DIR/projects.tsv"  # <repo절대경로>TAB<슬러그>
KC_QUEUE="$KC_DIR/queue.tsv"        # <unix시각>TAB<session_id>TAB<cwd>TAB<슬러그>TAB<transcript경로>

kc_configured() { [ -f "$KC_CONFIG" ]; }

# $1 = 키 이름. config의 KEY=VALUE에서 값을 출력 (없으면 빈 출력)
kc_config_get() {
  [ -f "$KC_CONFIG" ] || return 0
  awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$KC_CONFIG"
}

# $1 = 경로. 심볼릭 링크·상대경로를 푼 절대경로 출력 (존재하지 않으면 빈 출력)
kc_canonical() {
  [ -n "${1:-}" ] || return 0
  (cd "$1" 2>/dev/null && pwd -P) || true
}

# $1 = 디렉토리. 등록 repo 경로와 같거나 그 하위면 슬러그 출력, 아니면 빈 출력
kc_project_slug() {
  [ -f "$KC_PROJECTS" ] || return 0
  awk -F'\t' -v d="$1" '$1 != "" && (d == $1 || index(d, $1 "/") == 1) { print $2; exit }' "$KC_PROJECTS"
}

# $1 = session_id. 대기열에 이미 있으면 0
kc_in_queue() {
  [ -f "$KC_QUEUE" ] || return 1
  awk -F'\t' -v s="$1" '$2 == s { found=1 } END { exit !found }' "$KC_QUEUE"
}
