# 커밋 트리거 캡처 절차

commit-capture 훅이 "[kc] git commit 감지" 신호를 줬을 때 따르는 절차.
`$VAULT_PATH`, 작성자 이름은 `~/.claude/kc/config`에서 읽는다.
환경변수 `KC_DIR`가 설정돼 있으면 이 문서의 `~/.claude/kc`를 그 경로로 대체한다 (훅과 동일 규칙).

## 0. 기록 가치 판단

방금 커밋의 내용과 이 세션의 작업 과정을 돌아본다:
- 사소한 커밋(오타·포맷·단순 버전업·기계적 리네임) → **아무것도 하지 않는다. 사용자에게 언급도 하지 않는다**
- 의미 있는 일단락(결정, 시도와 폐기, 설계 변경, 조사 결과) → 1로 진행

## 1. 프로젝트 등록 (미등록 repo인 경우만)

- repo 디렉토리명 기반 kebab-case 슬러그를 제안하며 "이 repo를 vault 프로젝트로 등록할까요?" 확인
- 승인 시:
  - `printf '%s\t%s\n' "<repo 절대경로>" "<슬러그>" >> ~/.claude/kc/projects.tsv`
  - `$VAULT_PATH/_meta/templates/project-index.md`를 기반으로 `projects/<슬러그>/_index.md` 생성
    (목적·현재 상태는 사용자에게 한두 문장 묻거나 이 세션의 맥락으로 채운다),
    `projects/<슬러그>/context/` 디렉토리 생성, vault-git-flow.md 절차로 커밋·push
- 거절 시 종료. 이 세션에서 다시 제안하지 않는다

## 2. 초안 제안

- `$VAULT_PATH/_meta/conventions.md`를 읽고 스키마·배치 기준·링크 규칙을 따른다
- 이 세션의 작업 과정에서 **사고의 흐름**을 요약한 초안을 만든다:
  배경 / 사고의 흐름(무엇을 시도 → 왜 폐기 → 왜 이 선택) / 결론 / 다음 단계·미해결 / 연관
- 배치 제안: 프로젝트 종속 → `projects/<슬러그>/context/YYYY-MM-DD-<주제>.md`,
  범용 지식 → `topics/<주제>.md` (출처 프로젝트 링크는 반드시 남김)
- frontmatter `topics:`와 `## 연관` 위키링크는 쌍으로 생성
- **비밀정보(자격증명·비밀키·내부 전용 URL)는 절대 포함하지 않는다**
- 초안 전문을 사용자에게 보여주고 확인받는다

## 3. 사용자 선택

- **승인**(수정 요청 반영 포함) → `status: approved`로 vault-git-flow.md 절차대로 반영
- **"나중에"** → 대기열 등록만 하고 종료:
  `printf '%s\t%s\t%s\t%s\t%s\n' "$(date +%s)" "manual-$(date +%Y%m%d%H%M%S)" "<cwd절대경로>" "<슬러그>" "-" >> ~/.claude/kc/queue.tsv`
- **거절** → 아무것도 하지 않는다. 강제하지 않는다
